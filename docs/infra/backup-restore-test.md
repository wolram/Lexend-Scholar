# LS-11 — Testar Restore de Backup do PostgreSQL

## Visão Geral

O teste de restore é executado mensalmente para validar que os backups são funcionais e que o processo de recuperação atende ao RTO/RPO definido em `docs/infra/rto-rpo.md`. Um backup não testado não é um backup confiável.

## Frequência e Responsabilidade

| Tipo de Teste       | Frequência | Responsável      | Ambiente Alvo |
|---------------------|-----------|-----------------|---------------|
| Restore parcial     | Mensal    | Eng. de Infra   | dev           |
| Restore completo    | Trimestral| Eng. de Infra   | staging       |
| Simulação de DR     | Semestral | Time de Infra   | staging isolado|

## Procedimento de Restore — Supabase PITR

### Pré-requisitos

- Acesso de owner ao projeto Supabase de destino
- Supabase Pro plan com PITR habilitado

### Passo a Passo

```bash
# 1. Acessar dashboard Supabase → Database → Backups → Point in Time
# 2. Selecionar o timestamp de restore desejado
# 3. Clicar "Restore to this point"
# 4. Confirmar: isso cria um novo projeto com os dados restaurados
#    (não sobrescreve o projeto original)

# 5. Conectar ao projeto restaurado e verificar
RESTORED_DB_URL="postgresql://postgres:<pw>@db.<restored-ref>.supabase.co:5432/postgres"
psql "$RESTORED_DB_URL" -c "SELECT count(*) FROM schools;"
psql "$RESTORED_DB_URL" -c "SELECT count(*) FROM students;"
psql "$RESTORED_DB_URL" -c "SELECT max(created_at) FROM attendance_records;"
```

## Procedimento de Restore — Backup Externo (S3)

### Script de Restore Completo

Salvar em `scripts/restore.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Uso: ./scripts/restore.sh <nome-do-backup> <target-db-url>
# Exemplo: ./scripts/restore.sh lexend_scholar_20250401_030000.sql.gz \
#            "postgresql://postgres:pw@db.<ref>.supabase.co:5432/postgres"

BACKUP_NAME="${1:?Informe o nome do arquivo de backup}"
TARGET_DB_URL="${2:?Informe a URL do banco de destino}"
BUCKET="s3://lexend-scholar-backups"
TMP_FILE="/tmp/restore_${BACKUP_NAME}"

echo "=== Lexend Scholar — Restore de Backup ==="
echo "Backup: $BACKUP_NAME"
echo "Destino: $TARGET_DB_URL"
echo ""

# Confirmação de segurança
read -p "ATENÇÃO: Este restore irá sobrescrever dados no banco de destino. Continuar? [yes/N] " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "Restore cancelado."
  exit 1
fi

# Baixar backup do S3
echo "Baixando backup do S3..."
aws s3 cp "$BUCKET/daily/$BACKUP_NAME" "$TMP_FILE"

# Verificar integridade
echo "Verificando integridade do arquivo..."
gzip -t "$TMP_FILE" && echo "OK — arquivo íntegro"

# Executar restore
echo "Iniciando restore..."
START_TIME=$(date +%s)
gunzip -c "$TMP_FILE" | psql "$TARGET_DB_URL" \
  --quiet \
  --set ON_ERROR_STOP=1

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Limpeza
rm -f "$TMP_FILE"

echo ""
echo "Restore concluído em ${DURATION}s"
echo ""

# Verificação pós-restore
echo "=== Verificação pós-restore ==="
psql "$TARGET_DB_URL" -c "
  SELECT
    (SELECT count(*) FROM schools)     AS schools,
    (SELECT count(*) FROM users)       AS users,
    (SELECT count(*) FROM students)    AS students,
    (SELECT count(*) FROM attendance_records) AS attendance,
    (SELECT max(created_at) FROM audit_logs) AS last_audit_log;
"
```

## Checklist de Validação Pós-Restore

Executar após qualquer restore bem-sucedido:

```sql
-- 1. Verificar contagens esperadas
SELECT
  (SELECT count(*) FROM schools)               AS total_schools,
  (SELECT count(*) FROM users)                 AS total_users,
  (SELECT count(*) FROM students)              AS total_students,
  (SELECT count(*) FROM academic_years)        AS total_years,
  (SELECT count(*) FROM classes)               AS total_classes,
  (SELECT count(*) FROM attendance_records)    AS total_attendance,
  (SELECT count(*) FROM grades)                AS total_grades,
  (SELECT count(*) FROM invoices)              AS total_invoices;

-- 2. Verificar integridade referencial
SELECT conname, conrelid::regclass, confrelid::regclass
FROM pg_constraint
WHERE contype = 'f'
AND NOT convalidated;  -- Deve retornar 0 linhas

-- 3. Verificar ENUMs intactos
SELECT typname FROM pg_type WHERE typtype = 'e' ORDER BY typname;

-- 4. Verificar extensões
SELECT name, default_version, installed_version
FROM pg_available_extensions
WHERE installed_version IS NOT NULL;

-- 5. Verificar RLS ativo
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = FALSE;
-- Deve retornar 0 linhas (todas tabelas com RLS)

-- 6. Verificar data do backup (deve estar próxima do RPO)
SELECT max(created_at) AS dados_mais_recentes FROM attendance_records;
SELECT max(created_at) AS dados_mais_recentes FROM grades;
```

## Resultado Esperado por Teste

| Verificação                    | Resultado Esperado                    |
|--------------------------------|----------------------------------------|
| Contagem de schools            | Igual ou próxima ao prod              |
| Integridade referencial        | 0 FK constraints inválidas            |
| RLS ativo                      | Todas as tabelas com `rowsecurity=t`  |
| Dados mais recentes            | Dentro da janela de RPO (≤ 1 hora)   |
| Tempo de restore < 5GB         | < 10 minutos                          |
| Tempo de restore 5-20GB        | < 30 minutos                          |

## Registro de Testes

Manter um log dos testes realizados:

| Data       | Tipo         | Backup Usado                     | Duração | Resultado | Responsável    |
|------------|-------------|----------------------------------|---------|-----------|----------------|
| 2026-04-12 | Restore completo | lexend_scholar_20260412_030000 | -       | Pendente  | -              |

## Automação via GitHub Actions

```yaml
# .github/workflows/restore-test.yml
name: Monthly Restore Test

on:
  schedule:
    - cron: '0 5 1 * *'  # 1º de cada mês às 05:00 UTC
  workflow_dispatch:

jobs:
  restore-test:
    name: Test Backup Restore
    runs-on: ubuntu-latest
    environment: staging

    steps:
      - uses: actions/checkout@v4

      - name: Install postgresql-client
        run: sudo apt-get install -y postgresql-client-15

      - name: Get latest backup filename
        id: backup
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          LATEST=$(aws s3 ls s3://lexend-scholar-backups/daily/ \
            --recursive | sort | tail -1 | awk '{print $4}')
          echo "file=$LATEST" >> $GITHUB_OUTPUT

      - name: Restore to staging
        env:
          SUPABASE_DB_URL: ${{ secrets.SUPABASE_DB_URL_STAGING }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          echo "yes" | bash scripts/restore.sh \
            "$(basename ${{ steps.backup.outputs.file }})" \
            "$SUPABASE_DB_URL"

      - name: Validate restore
        env:
          SUPABASE_DB_URL: ${{ secrets.SUPABASE_DB_URL_STAGING }}
        run: |
          psql "$SUPABASE_DB_URL" -c "
            SELECT count(*) AS schools FROM schools;
            SELECT count(*) AS users FROM users;
          "
```

## Referências

- `docs/infra/backup-strategy.md` — estratégia de backups
- `docs/infra/rto-rpo.md` — objetivos de RTO/RPO
- `scripts/backup.sh` — script de backup
- `scripts/restore.sh` — script de restore
