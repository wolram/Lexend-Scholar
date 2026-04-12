# Rollback Procedure — LexendScholar

Procedimentos de rollback para cada camada da stack do Lexend Scholar. Em caso de incidente, siga este documento na ordem indicada.

---

## Índice

1. [Quando fazer rollback](#1-quando-fazer-rollback)
2. [Rollback do Website (Vercel)](#2-rollback-do-website-vercel)
3. [Rollback do App iOS (TestFlight / App Store)](#3-rollback-do-app-ios-testflight--app-store)
4. [Rollback do Banco de Dados (Supabase)](#4-rollback-do-banco-de-dados-supabase)
5. [Rollback via Git (código-fonte)](#5-rollback-via-git-código-fonte)
6. [Checklist pós-rollback](#6-checklist-pós-rollback)
7. [Contatos de Emergência](#7-contatos-de-emergência)

---

## 1. Quando fazer rollback

Inicie o rollback imediatamente se **qualquer** condição abaixo for verdadeira:

| Condição | Severidade |
|---|---|
| Taxa de erro > 5% nas últimas 5 min | Crítica — rollback imediato |
| Autenticação quebrada (login/logout) | Crítica — rollback imediato |
| Dados de alunos inacessíveis | Crítica — rollback imediato |
| Crash rate > 2% no app iOS | Alta — rollback em 15 min |
| Página do website retornando 500/404 | Alta — rollback em 15 min |
| Build de CI quebrando > 30 min | Média — investigar antes de reverter |

**Regra geral:** Em caso de dúvida, faça rollback primeiro e investigue depois.

---

## 2. Rollback do Website (Vercel)

### Opção A: Via Dashboard Vercel (mais rápida — 2 minutos)

1. Acesse [vercel.com/lexendscholar](https://vercel.com/lexendscholar)
2. Clique no projeto `lexend-scholar`
3. Vá para a aba **Deployments**
4. Localize o último deployment estável (status verde, antes do problemático)
5. Clique nos três pontos `...` ao lado do deployment
6. Selecione **Promote to Production**
7. Confirme — o tráfego é redirecionado instantaneamente

### Opção B: Via Vercel CLI (recomendada para automação)

```bash
# Instalar CLI se necessário
npm install -g vercel

# Autenticar
vercel login

# Listar deployments recentes
vercel ls --limit 10

# Promover deployment específico para produção
# (copie a URL do deployment estável da listagem acima)
vercel promote <deployment-url>

# Exemplo:
# vercel promote https://lexend-scholar-abc123def.vercel.app
```

### Opção C: Via git revert (se o problema é no código)

```bash
# Identificar o commit problemático
git log --oneline -10

# Reverter o commit problemático (cria novo commit de reversão)
git revert <commit-hash>

# Push para main — o Vercel detecta e faz novo deploy automaticamente
git push origin main
```

### Verificação pós-rollback (Website)

```bash
# Verificar que o site está respondendo
curl -I https://lexendscholar.com.br

# Verificar status HTTP de páginas críticas
curl -o /dev/null -s -w "%{http_code}" https://lexendscholar.com.br/
curl -o /dev/null -s -w "%{http_code}" https://lexendscholar.com.br/precos
curl -o /dev/null -s -w "%{http_code}" https://lexendscholar.com.br/contato
```

---

## 3. Rollback do App iOS (TestFlight / App Store)

### 3.1 Rollback em TestFlight (Beta)

**Cenário:** versão beta problemática enviada para testadores.

1. Acesse [App Store Connect](https://appstoreconnect.apple.com)
2. Selecione o app **LexendScholar**
3. Vá em **TestFlight** → **Builds**
4. Localize a build problemática
5. Clique em **Expire Build** para remover do TestFlight
6. A versão anterior (ainda ativa) volta a ser a disponível para testadores

**Via Xcode Cloud:**
- Acesse **Xcode** → **Product** → **Xcode Cloud** → selecione o workflow
- Cancele qualquer build em progresso
- Re-execute o workflow apontando para um commit anterior:
  - Em **Start Build**, selecione a branch e especifique o commit SHA desejado

### 3.2 Rollback em Produção (App Store)

**ATENÇÃO:** A Apple não permite rollback direto de versões já publicadas na App Store. As opções são:

**Opção A: Remover do sale temporariamente**
1. App Store Connect → **Pricing and Availability**
2. Desmarque todos os territórios em **Availability**
3. O app fica invisível para novos downloads enquanto você prepara o hotfix
4. Usuários que já instalaram continuam com a versão atual (sem reversão automática)

**Opção B: Hotfix acelerado (preferencial)**
1. Faça `git revert` do(s) commit(s) problemáticos na `main`
2. Bump da versão para o próximo patch (ex: 1.2.3 → 1.2.4)
3. Submit para App Store com flag **Emergency Developer Hotfix** na justificativa
4. A Apple prioriza reviews de emergência (geralmente 24-48h)

**Opção C: Forçar atualização via feature flag**
1. No Supabase, ative uma feature flag de manutenção via Remote Config
2. O app detecta a flag e exibe tela de manutenção até a nova versão ser aprovada

### 3.3 Revertendo o build no repositório

```bash
# Identificar o commit do build problemático
git log --oneline --grep="LS-" -20

# Reverter para o estado anterior ao problema
git revert HEAD~1   # ou especifique o hash exato

# Push — o iOS CD workflow inicia novo build automaticamente
git push origin main
```

---

## 4. Rollback do Banco de Dados (Supabase)

### 4.1 Reverter migração SQL

```bash
# Acessar o Supabase CLI (instalar: brew install supabase/tap/supabase)
supabase db reset --db-url postgresql://postgres:<senha>@db.<projeto>.supabase.co:5432/postgres

# OU executar SQL de rollback manualmente via Supabase Studio:
# Dashboard → SQL Editor → colar e executar o script de rollback
```

### 4.2 Restore de backup (Supabase Point-in-Time Recovery)

Disponível nos planos Pro e superiores:

1. Acesse [Supabase Dashboard](https://supabase.com/dashboard) → projeto → **Database**
2. Clique em **Backups** → **Point in Time Recovery**
3. Selecione o timestamp desejado (antes do incidente)
4. Clique em **Restore** — o processo leva aproximadamente 5-15 minutos

**IMPORTANTE:** O restore sobreescreve os dados atuais. Faça um snapshot manual antes:

```sql
-- No SQL Editor do Supabase, antes do restore:
-- Exportar tabelas críticas para backup temporário
CREATE TABLE students_backup_rollback AS SELECT * FROM students;
CREATE TABLE enrollments_backup_rollback AS SELECT * FROM enrollments;
CREATE TABLE grades_backup_rollback AS SELECT * FROM grades;
```

### 4.3 Reverter migração específica

Cada migração deve ter um arquivo de rollback correspondente em `sql/migrations/`:

```bash
# Convenção de nomes:
# sql/migrations/001_add_students_table.sql       → migração
# sql/migrations/001_add_students_table.down.sql  → rollback

# Executar rollback de migração específica:
psql $DATABASE_URL < sql/migrations/001_add_students_table.down.sql
```

---

## 5. Rollback via Git (código-fonte)

### Reverter um único commit

```bash
git revert <commit-hash>
git push origin main
```

### Reverter múltiplos commits (mantendo histórico)

```bash
# Reverter os últimos 3 commits
git revert HEAD~3..HEAD
git push origin main
```

### Retornar a uma tag de release específica (estado limpo)

```bash
# Listar tags existentes
git tag --sort=-version:refname | head -10

# Criar branch de hotfix a partir da última release estável
git checkout -b hotfix/rollback-v1.2.2 v1.2.2

# Fazer correções necessárias e abrir PR para main
```

---

## 6. Checklist pós-rollback

Após executar o rollback, verificar TODOS os itens abaixo antes de declarar incidente resolvido:

### Website
- [ ] Página inicial carrega em < 3s
- [ ] Todas as rotas principais retornam HTTP 200
- [ ] Links de CTA funcionam corretamente
- [ ] Formulário de contato é submetido com sucesso
- [ ] Analytics (se configurado) recebendo eventos

### App iOS
- [ ] App abre sem crash na tela inicial
- [ ] Login/logout funcionam
- [ ] Listagem de alunos carrega
- [ ] Notas são exibidas corretamente
- [ ] Nenhum erro no Sentry nas últimas 5 min

### Banco de Dados
- [ ] Queries de leitura respondem em < 500ms
- [ ] Writes são aceitos sem erro
- [ ] RLS policies funcionando (testar com usuário não-admin)
- [ ] Backups automáticos do Supabase rodando (checar no Dashboard)

### CI/CD
- [ ] Próximo push para `main` aciona os workflows corretamente
- [ ] TestFlight build enviado com sucesso após rollback
- [ ] Vercel deployment marcado como produção ativo

---

## 7. Contatos de Emergência

| Serviço | Contato / Link |
|---|---|
| Vercel Status | [vercel-status.com](https://vercel-status.com) |
| Supabase Status | [status.supabase.com](https://status.supabase.com) |
| Apple Developer | [developer.apple.com/contact](https://developer.apple.com/contact) |
| GitHub Status | [githubstatus.com](https://www.githubstatus.com) |

**Tempo máximo tolerável por nível:**

| Severidade | Tempo de resposta | Responsável |
|---|---|---|
| Crítica | 15 minutos | Qualquer eng disponível |
| Alta | 1 hora | Eng de plantão |
| Média | 4 horas | Time de produto |
| Baixa | Próximo dia útil | Time de produto |
