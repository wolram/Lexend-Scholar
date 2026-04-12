# LS-10 — Definir RTO e RPO para o Sistema Escolar

## Visão Geral

Este documento define os objetivos de tempo de recuperação (RTO) e ponto de recuperação (RPO) para o Lexend Scholar, com base na criticidade de cada componente do sistema.

## Definições

- **RTO (Recovery Time Objective)**: tempo máximo aceitável de indisponibilidade após um incidente
- **RPO (Recovery Point Objective)**: quantidade máxima aceitável de perda de dados (janela de tempo desde o último backup válido)

## Classificação de Componentes por Criticidade

| Nível       | Descrição                                    |
|-------------|----------------------------------------------|
| **Crítico** | Falha impede operação do dia escolar         |
| **Alto**    | Falha impacta funções importantes mas há workaround |
| **Médio**   | Falha incomoda mas não paralisa operações    |
| **Baixo**   | Falha de baixo impacto, pode aguardar        |

## Tabela de RTO e RPO por Componente

| Componente                     | Criticidade | RTO     | RPO     | Justificativa                                   |
|--------------------------------|-------------|---------|---------|--------------------------------------------------|
| PostgreSQL (Supabase)          | Crítico     | 1 hora  | 1 hora  | Todos os dados do sistema dependem do banco      |
| Autenticação (Supabase Auth)   | Crítico     | 30 min  | 15 min  | Sem auth, nenhum usuário consegue acessar        |
| API REST (Supabase / PostgREST)| Crítico     | 1 hora  | 1 hora  | App iOS e Web dependem da API                    |
| Realtime (Supabase Realtime)   | Alto        | 4 horas | N/A     | Recurso importante mas não bloqueia uso básico   |
| Storage (Supabase Storage)     | Alto        | 4 horas | 4 horas | Upload de documentos pode aguardar               |
| Web App (Vercel)               | Alto        | 2 horas | N/A     | iOS app funciona independentemente               |
| iOS App                        | Crítico     | N/A*    | N/A     | Cliente — indisponibilidade é do backend         |
| Stripe / Pagamentos            | Médio       | 24 h    | 1 hora  | Cobranças podem aguardar; dados nunca perder     |
| Notificações Push (APNs)       | Baixo       | 24 h    | N/A     | Não bloqueia operação principal                  |
| Sentry (Monitoramento)         | Baixo       | 48 h    | N/A     | Ferramenta de observabilidade, não produto       |

*iOS App: distribuído via App Store — não há conceito de RTO para o app em si; o RTO refere-se aos serviços de backend.

## SLA de Disponibilidade

| Componente         | SLA Target | Downtime Máximo/Mês |
|--------------------|-----------|---------------------|
| Supabase (managed) | 99.9%     | ~44 min/mês         |
| Vercel             | 99.99%    | ~4 min/mês          |
| Sistema geral      | 99.5%     | ~3.6 h/mês          |

> O SLA de 99.5% do sistema é limitado pelo Supabase Free/Pro. Para SLA maior, usar Supabase Team/Enterprise.

## Cenários de Falha e Estratégia de Recuperação

### Cenário 1: Falha Total do Banco de Dados

**Probabilidade**: Baixa | **Impacto**: Crítico

1. Verificar status em `status.supabase.com`
2. Se falha do Supabase: aguardar recuperação gerenciada (RTO Supabase ~1h)
3. Se corrupção de dados: iniciar restore de backup (ver `docs/infra/backup-restore-test.md`)
4. Notificar clientes via página de status e e-mail
5. Ativar plano de contingência (ver `docs/infra/contingency-plan.md`)

**Tempo estimado de recuperação**: 30 min – 2 h

### Cenário 2: Deploy com Regressão Crítica

**Probabilidade**: Média | **Impacto**: Alto

1. Identificar o commit problemático via Sentry
2. Executar rollback no Vercel: `vercel rollback` ou dashboard
3. Se necessário, reverter migration: `supabase db reset` ou rollback manual
4. Comunicar equipe via Slack

**Tempo estimado de recuperação**: 5 – 30 min

### Cenário 3: Comprometimento de Secrets

**Probabilidade**: Baixa | **Impacto**: Crítico

1. Revogar imediatamente o secret comprometido (dashboard Supabase / Stripe / GitHub)
2. Gerar novas credenciais
3. Atualizar GitHub Secrets e Vercel env vars
4. Redeploy imediato de produção
5. Auditar logs de acesso das últimas 72h
6. Notificar usuários se dados foram expostos (obrigação LGPD: 72h)

**Tempo estimado de resposta inicial**: < 15 min

### Cenário 4: Perda de Dados (Deleção Acidental)

**Probabilidade**: Baixa | **Impacto**: Crítico

1. Usar PITR (Point-in-Time Recovery) do Supabase para restaurar ao momento anterior à deleção
2. Se além da janela de PITR (>24h no Pro): usar backup diário do S3
3. Verificar `audit_logs` para identificar o escopo da perda
4. Comunicar tenant afetado

**RPO efetivo**: depende do horário da deleção vs. último backup (máx 1h com PITR)

## Janelas de Manutenção

- **Manutenção planejada**: Domingos entre 02:00 – 04:00 BRT (baixo uso)
- **Notificação prévia**: mínimo 48h de antecedência via e-mail + in-app banner
- **Duração máxima**: 2 horas por janela

## Monitoramento e Alertas

Para garantir RTO, o monitoramento proativo é essencial:

| Check                    | Frequência | Alert em              |
|--------------------------|-----------|----------------------|
| Health check da API      | 1 min     | Falha por > 2 min    |
| Latência do banco        | 5 min     | P95 > 2s             |
| Taxa de erros 5xx        | 1 min     | > 1% das requisições |
| Falha de autenticação    | 5 min     | > 10 falhas/min      |
| Espaço em disco          | 15 min    | > 80% utilizado      |
| Backup status            | Diário    | Falha no backup      |

Ver `docs/infra/uptime-sla.md` para configuração completa de alertas.

## Comunicação em Incidentes

### Canais

- **Slack**: `#incidents` para comunicação interna
- **Status Page**: `status.lexendscholar.com.br` (via BetterStack ou Statuspage.io)
- **E-mail**: notificação para admins das escolas afetadas
- **In-app banner**: se o app ainda estiver parcialmente operacional

### Severidades e Escalação

| Severidade | Definição                              | Resposta Inicial | Escalação  |
|------------|----------------------------------------|-----------------|------------|
| P1         | Sistema indisponível para todos        | 15 min          | Imediata   |
| P2         | Funcionalidade crítica indisponível    | 30 min          | 1 hora     |
| P3         | Degradação de performance              | 2 horas         | 4 horas    |
| P4         | Bug não crítico                        | Próximo dia útil| Semanal    |

## Revisão e Atualização

Este documento deve ser revisado:
- Trimestralmente por padrão
- Após qualquer incidente P1 ou P2
- Após mudanças significativas na arquitetura

Próxima revisão: **Julho de 2026**

## Referências

- `docs/infra/backup-strategy.md` — estratégia de backups
- `docs/infra/backup-restore-test.md` — teste de restore
- `docs/infra/contingency-plan.md` — plano de contingência
- `docs/infra/uptime-sla.md` — monitoramento e SLA
- [Supabase Status](https://status.supabase.com)
- [Vercel Status](https://www.vercel-status.com)
