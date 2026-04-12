# LS-5 — Estratégia de Backups Automáticos

## Visão Geral

A estratégia de backup do Lexend Scholar combina os backups gerenciados do Supabase com backups adicionais exportados para armazenamento externo, garantindo conformidade com LGPD e atendendo aos objetivos de RTO/RPO definidos em `docs/infra/rto-rpo.md`.

## Backups Gerenciados pelo Supabase

O Supabase Pro/Team inclui backups automáticos gerenciados:

| Plano        | Frequência   | Retenção  | Point-in-Time Recovery |
|--------------|-------------|-----------|------------------------|
| Free         | Diário       | 1 semana  | Não                    |
| Pro          | Diário       | 7 dias    | Sim (últimas 24h)      |
| Team/Enterprise | A cada hora | 30 dias  | Sim (últimos 7 dias)   |

**Recomendação**: Usar plano **Pro** em produção (mínimo) ou **Team** para PITR de 7 dias.

### Como Restaurar via Dashboard

1. Acessar Supabase Dashboard → **Database → Backups**
2. Selecionar o backup desejado
3. Clicar em **Restore** e confirmar
4. Aguardar processo (estimativa: ~15 min para banco < 5GB)

## Backups Adicionais para Armazenamento Externo

Complementar os backups Supabase com exports diários para S3/R2:

### Script de Backup

Salvar em `scripts/backup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuração
DB_URL="${SUPABASE_DB_URL}"
BUCKET="s3://lexend-scholar-backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/tmp/backups"
FILENAME="lexend_scholar_${TIMESTAMP}.sql.gz"

mkdir -p "$BACKUP_DIR"

echo "Iniciando backup: $FILENAME"

# Dump completo comprimido
pg_dump "$DB_URL" \
  --no-owner \
  --no-acl \
  --clean \
  --if-exists \
  --format=plain \
  | gzip > "$BACKUP_DIR/$FILENAME"

echo "Backup local criado: $(du -h "$BACKUP_DIR/$FILENAME" | cut -f1)"

# Upload para S3 (ou Cloudflare R2)
aws s3 cp "$BACKUP_DIR/$FILENAME" "$BUCKET/daily/$FILENAME" \
  --storage-class STANDARD_IA \
  --server-side-encryption aws:kms

# Upload para bucket de longa retenção (mensal)
DAY_OF_MONTH=$(date +%d)
if [ "$DAY_OF_MONTH" = "01" ]; then
  aws s3 cp "$BACKUP_DIR/$FILENAME" "$BUCKET/monthly/$FILENAME" \
    --storage-class GLACIER \
    --server-side-encryption aws:kms
  echo "Backup mensal enviado para Glacier"
fi

# Limpeza local
rm -f "$BACKUP_DIR/$FILENAME"

echo "Backup concluído: $FILENAME"
```

### GitHub Actions — Backup Diário

Arquivo: `.github/workflows/backup.yml`

```yaml
name: Daily Database Backup

on:
  schedule:
    - cron: '0 3 * * *'  # 03:00 UTC = 00:00 BRT
  workflow_dispatch:

jobs:
  backup:
    name: Backup PostgreSQL
    runs-on: ubuntu-latest
    environment: production

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install pg_dump
        run: |
          sudo apt-get update -qq
          sudo apt-get install -y postgresql-client-15

      - name: Run backup script
        env:
          SUPABASE_DB_URL: ${{ secrets.SUPABASE_DB_URL_PROD }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_DEFAULT_REGION: us-east-1
        run: bash scripts/backup.sh

      - name: Notify on failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {"text": "ALERTA: Backup do banco de dados FALHOU em produção!"}
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## Política de Retenção

| Tipo de Backup       | Frequência    | Retenção  | Destino         |
|----------------------|--------------|-----------|-----------------|
| Supabase automático  | Diário       | 7 dias    | Supabase managed|
| Export SQL comprimido| Diário       | 30 dias   | S3 (Standard-IA)|
| Export SQL mensal    | 1º de cada mês| 1 ano    | S3 (Glacier)    |
| PITR (Pro plan)      | Contínuo     | 24h       | Supabase managed|

## Lifecycle Policy no S3

```json
{
  "Rules": [
    {
      "Id": "daily-backups-lifecycle",
      "Filter": {"Prefix": "daily/"},
      "Status": "Enabled",
      "Transitions": [
        {"Days": 30, "StorageClass": "GLACIER"}
      ],
      "Expiration": {"Days": 365}
    },
    {
      "Id": "monthly-backups-lifecycle",
      "Filter": {"Prefix": "monthly/"},
      "Status": "Enabled",
      "Transitions": [
        {"Days": 90, "StorageClass": "DEEP_ARCHIVE"}
      ],
      "Expiration": {"Days": 2555}
    }
  ]
}
```

## Checklist de Backup

- [ ] Supabase Pro plan ativo em produção
- [ ] PITR habilitado no dashboard Supabase
- [ ] Bucket S3 `lexend-scholar-backups` criado com encryption e versioning
- [ ] IAM user com permissões apenas de PutObject para o bucket
- [ ] GitHub Actions workflow `backup.yml` configurado e testado
- [ ] Secrets configurados: `SUPABASE_DB_URL_PROD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- [ ] Alerta de falha de backup configurado no Slack/email
- [ ] Teste de restore documentado e executado mensalmente (ver `docs/infra/backup-restore-test.md`)

## Conformidade LGPD

- Backups criptografados em repouso (AES-256)
- Acesso restrito a administradores de infra
- Logs de acesso ao bucket habilitados
- Dados pessoais de backups cobertos pela política de privacidade
- Processo de exclusão de dados de tenant inclui invalidação de backups após 90 dias da exclusão

## Referências

- `docs/infra/rto-rpo.md` — objetivos de recuperação
- `docs/infra/backup-restore-test.md` — procedimento de teste de restore
- `scripts/backup.sh` — script de backup
- [Supabase Backups](https://supabase.com/docs/guides/platform/backups)
