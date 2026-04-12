# LS-12 — Plano de Contingência para Indisponibilidade

## Visão Geral

Este plano define os procedimentos a seguir quando componentes críticos do Lexend Scholar ficam indisponíveis, minimizando o impacto para as escolas clientes.

## Estrutura de Resposta a Incidentes

### Papéis

| Papel                   | Responsabilidade                                       |
|-------------------------|--------------------------------------------------------|
| Incident Commander (IC) | Coordena a resposta, toma decisões finais              |
| Eng. de Infra           | Executa ações técnicas, diagnóstico e recuperação      |
| Eng. de Backend         | Analisa código, reverte deploys se necessário          |
| Comunicação             | Atualiza status page e notifica clientes               |

### Canal de Comunicação

- **Primário**: Slack `#incidents` (alerta automático via PagerDuty/BetterStack)
- **Bridge de voz**: Google Meet link permanente em `docs/infra/incident-bridge.md`
- **Secundário**: WhatsApp grupo `Lexend Infra`

## Cenários e Playbooks

---

### Cenário A: Supabase Totalmente Indisponível

**Detecção**: Alertas de health check + `status.supabase.com` mostrando incidente

**Severidade**: P1

**Playbook**:

```
T+0min    IC declara incidente P1 no #incidents
T+5min    Verificar status.supabase.com para ETA de recuperação
T+10min   Ativar modo de manutenção no Vercel (maintenance page)
T+10min   Atualizar status page (status.lexendscholar.com.br)
T+10min   Enviar e-mail para admins das escolas
T+15min   Verificar se PITR ou failover para projeto de backup é viável
T+30min   Update de status para clientes
T+60min   Se Supabase ainda indisponível: avaliar restore em PostgreSQL alternativo
T+Xmin    Quando Supabase recuperar: desativar modo manutenção, validar dados
T+Xmin    Post-mortem agendado para próximas 48h
```

**Modo de Manutenção no Vercel**:

```bash
# Ativar página de manutenção
vercel env add MAINTENANCE_MODE true production --yes
vercel redeploy --prod

# Desativar
vercel env rm MAINTENANCE_MODE production --yes
vercel redeploy --prod
```

---

### Cenário B: Vercel Web App Indisponível

**Detecção**: Health check falha / `www.vercel-status.com` mostra incidente

**Severidade**: P2 (iOS app ainda funciona)

**Playbook**:

```
T+0min    Verificar status Vercel em vercel-status.com
T+5min    Verificar último deployment no dashboard Vercel
T+10min   Tentar rollback para deployment anterior: `vercel rollback`
T+15min   Se rollback falhar: redeploy manual da branch main
T+20min   Se Vercel em outage: DNS failover para Cloudflare Pages (backup estático)
T+20min   Notificar usuários web — ressaltar que iOS app funciona normalmente
T+Xmin    Quando resolvido: validar todos os endpoints críticos
```

**Rollback Vercel**:

```bash
# Listar deployments recentes
vercel list

# Rollback para deployment anterior
vercel rollback <deployment-url>

# Ou via GitHub Actions
gh workflow run deploy.yml --ref <commit-sha-estavel>
```

---

### Cenário C: Falha em Deploy (Regressão)

**Detecção**: Aumento de erros 5xx no Sentry / alertas pós-deploy

**Severidade**: P2

**Playbook**:

```
T+0min    Identificar que o problema começou após deploy recente
T+5min    Rollback imediato no Vercel (< 2 min para ser efetivo)
T+10min   Verificar se migration de banco foi parte do deploy
T+15min   Se migration causou problema: executar migration de rollback
T+20min   Abrir issue de regressão com stack trace do Sentry
T+30min   Confirmar que erros 5xx voltaram ao baseline
```

**Rollback de Migration**:

```bash
# Ver migrations aplicadas
supabase db migrations list

# Criar migration de rollback manualmente
# (Supabase não tem rollback automático)
psql "$SUPABASE_DB_URL" -f supabase/migrations/ROLLBACK_20240101000003.sql
```

---

### Cenário D: Comprometimento de Segurança

**Detecção**: Alerta de segurança / acesso não autorizado detectado

**Severidade**: P1 — Resposta imediata

**Playbook**:

```
T+0min    Revogar IMEDIATAMENTE o secret comprometido
T+5min    Inativar usuário suspeito no Supabase Auth (se aplicável)
T+5min    Habilitar modo de manutenção para conter o dano
T+10min   Auditar audit_logs e Supabase Auth Logs das últimas 72h
T+15min   Gerar novos secrets e fazer redeploy
T+30min   Avaliar escopo do comprometimento: quais dados foram expostos?
T+60min   Notificar DPO (Data Protection Officer) se dados pessoais expostos
T+72h     Notificar ANPD se obrigação LGPD (vazamento de dados pessoais)
T+72h     Notificar escolas afetadas com detalhes do incidente
```

**Revogar Service Role Key**:

```
Supabase Dashboard → Settings → API → Service Role Key → Reveal → Regenerate
```

---

### Cenário E: Falha de Pagamentos (Stripe)

**Detecção**: Webhooks Stripe falhando / relatórios de cobrança com problemas

**Severidade**: P2

**Playbook**:

```
T+0min    Verificar status.stripe.com
T+10min   Verificar logs de webhook no dashboard Stripe → Webhooks → Logs
T+15min   Reenviar webhooks falhados manualmente via dashboard Stripe
T+15min   Verificar STRIPE_WEBHOOK_SECRET — pode ter expirado/sido rotacionado
T+30min   Se Stripe em outage: registrar pagamentos pendentes para reprocessamento
T+Xmin    Reprocessar cobranças pendentes após recuperação
```

---

## Página de Status

Configurar em BetterStack (recomendado) ou Statuspage.io:

- URL: `status.lexendscholar.com.br`
- Componentes monitorados:
  - API Backend (Supabase)
  - Web App (Vercel)
  - Autenticação
  - Processamento de Pagamentos
  - Notificações Push

```bash
# BetterStack CLI — atualizar status
betterstack incidents create \
  --title "Indisponibilidade do banco de dados" \
  --severity "critical" \
  --affected-components "api-backend"
```

## Comunicação com Clientes

### Template de E-mail — Incidente Ativo

```
Assunto: [Lexend Scholar] Indisponibilidade em andamento — [Data]

Prezados administradores,

Estamos cientes de uma indisponibilidade que está afetando o Lexend Scholar.

Impacto: [descrição do impacto]
Início: [horário]
Status atual: [investigando / mitigando / resolvido]

Nossa equipe técnica está trabalhando ativamente na resolução.
Atualizações a cada 30 minutos em: status.lexendscholar.com.br

Pedimos desculpas pelo inconveniente.

Equipe Lexend Scholar
```

### Template — Resolução

```
Assunto: [Resolvido] Indisponibilidade do Lexend Scholar — [Data]

Informamos que o incidente foi resolvido às [horário].

Causa: [breve descrição]
Duração: [X horas/minutos]
Dados afetados: [sim/não — detalhar se sim]

Estamos publicando um post-mortem completo em [link] nas próximas 48h.

Obrigado pela paciência.
```

## Post-Mortem

Todo incidente P1 ou P2 deve ter um post-mortem documentado em `docs/infra/post-mortems/YYYY-MM-DD-titulo.md` com:

1. **Resumo executivo** (3 linhas)
2. **Linha do tempo** dos eventos
3. **Causa raiz** (5 Whys)
4. **Impacto** (usuários afetados, dados perdidos, receita)
5. **O que funcionou bem**
6. **O que pode melhorar**
7. **Action items** com responsável e prazo

## Contatos de Emergência

| Serviço    | Suporte                                   | SLA de Resposta |
|------------|-------------------------------------------|-----------------|
| Supabase   | support.supabase.com / Discord            | 24h (Pro)       |
| Vercel     | vercel.com/support                        | 24h             |
| Stripe     | support.stripe.com / dashboard            | Imediato (P1)   |
| AWS (S3)   | console.aws.amazon.com/support            | 4h (Business)   |

## Referências

- `docs/infra/rto-rpo.md` — objetivos de recuperação
- `docs/infra/backup-restore-test.md` — procedimento de restore
- `docs/infra/rollback-procedure.md` — rollback de deployments
- `docs/infra/uptime-sla.md` — monitoramento e alertas
