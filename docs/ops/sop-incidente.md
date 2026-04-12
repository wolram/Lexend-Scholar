# SOP: Resposta a Incidentes — Lexend Scholar

**Versão**: 1.0
**Owner**: Operações / Engineering
**Última atualização**: Abril 2026

---

## Classificação de Incidentes (P0-P3)

| Prioridade | Definição | Exemplos | SLA de Resolução |
|---|---|---|---|
| **P0 — Crítico** | Serviço totalmente indisponível ou perda de dados | App/web completamente fora, banco de dados inacessível, vazamento de dados em produção | < 4 horas |
| **P1 — Alto** | Feature crítica inoperante para todos os usuários | Frequência não salva, notas não aparecem, pagamentos falhando | < 24 horas |
| **P2 — Médio** | Feature degradada, workaround possível | Relatórios lentos, notificações atrasadas, upload de documentos instável | < 72 horas |
| **P3 — Baixo** | Problema cosmético ou de UX | Botão com posição errada, texto cortado, tooltip ausente | < 2 semanas |

---

## Runbook de Resposta a Incidentes

### Passo 1: Detecção

**Fontes de detecção:**
- Alertas automáticos do Sentry (error rate spike)
- Alertas do Uptime Robot / Better Uptime (site down)
- Alertas do Cloudwatch / Supabase (banco de dados)
- Reporte de cliente via Crisp ou WhatsApp
- Monitoramento manual pelo time

**Ação imediata ao detectar:**
1. Confirmar que o incidente é real (não falso positivo)
2. Acessar o sistema como usuário de teste para verificar o impacto
3. Classificar a prioridade (P0-P3) em até 5 minutos

---

### Passo 2: Comunicação Inicial

**Para P0 e P1:**

Notificar imediatamente o canal Slack `#incidentes`:
```
[INCIDENTE P0] 🔴 {data e hora}
Problema: {descrição em 1 linha}
Impacto: {quem/o que está afetado}
Detectado via: {Sentry / cliente / monitoramento}
Responsável pela investigação: {nome}
Status: Investigando
```

**Para P0:** Notificar os co-fundadores via WhatsApp diretamente.

**Para clientes afetados (P0 e P1 Enterprise):**
```
Olá,

Identificamos um problema técnico que pode estar afetando o uso do Lexend Scholar.
Nossa equipe está trabalhando ativamente na resolução.
Próxima atualização em 30 minutos.

Equipe Lexend Scholar
```

---

### Passo 3: Contenção

**Objetivos da fase de contenção:**
- Parar o incidente de se alastrar
- Proteger os dados dos clientes
- Manter comunicação ativa

**Ações de contenção por tipo:**

**App/API fora do ar:**
1. Verificar status do Supabase: status.supabase.com
2. Verificar status do Vercel: vercel-status.com
3. Se deploy recente causou o problema → rollback imediato:
   ```bash
   vercel rollback  # Web
   # iOS: submeter hotfix ou comunicar usuários para usar versão anterior
   ```
4. Verificar logs em tempo real: Vercel Functions → Logs

**Banco de dados com problemas:**
1. Acessar Supabase Dashboard → Database → Logs
2. Verificar queries lentas: Supabase → Database → Query Performance
3. Verificar espaço em disco: Supabase → Storage → Database Size
4. Se necessário, escalar o plano temporariamente

**Vazamento de dados:**
1. **IMEDIATAMENTE**: Revogar tokens de acesso comprometidos
2. Isolar o sistema afetado (desabilitar endpoint, se possível)
3. Acionar o DPO para iniciar protocolo LGPD (72h para ANPD)
4. Não deletar logs — preservar evidências

---

### Passo 4: Investigação e Diagnóstico

**Ferramentas de diagnóstico:**

```bash
# Verificar erros no Sentry
# Acessar: sentry.io/organizations/lexend-scholar/issues/

# Verificar logs da API (Vercel)
vercel logs --app lexend-scholar-api --since 1h

# Verificar logs do Supabase
# Supabase Dashboard → Database → Logs → Filter por "error"

# Testar endpoint específico
curl -i https://api.lexendscholar.com/health
curl -i https://api.lexendscholar.com/api/v1/schools

# Verificar métricas do banco
# Supabase → Reports → Database → CPU, Memory, Connections
```

**Perguntas de diagnóstico:**
1. Quando o incidente começou exatamente?
2. Houve algum deploy nas últimas 2 horas?
3. O problema afeta todos os clientes ou apenas alguns?
4. Há padrão nos erros (mesmo endpoint, mesma região, mesmo plano)?
5. O problema é determinístico (sempre falha) ou intermitente?

---

### Passo 5: Erradicação

Após identificar a causa raiz:

1. Implementar o fix (mínimo necessário para resolver o incidente)
2. Revisar o fix com pelo menos 1 outra pessoa
3. Testar em staging se houver tempo (P0: pode ir direto para produção com monitoramento intenso)
4. Fazer o deploy
5. Verificar que o incidente foi resolvido via monitoramento e teste manual

---

### Passo 6: Recuperação

1. Confirmar que o serviço está estável por pelo menos 15 minutos
2. Atualizar status para clientes afetados:
   ```
   O problema foi resolvido às {hora}. O serviço está funcionando normalmente.
   Caso ainda experimente problemas, por favor entre em contato.
   ```
3. Atualizar o Slack `#incidentes`:
   ```
   [RESOLVIDO P0] ✅ {hora de resolução}
   Duração: {X horas Y minutos}
   Causa raiz: {descrição breve}
   Resolução: {o que foi feito}
   Postmortem: será publicado em {data}
   ```
4. Restaurar qualquer sistema que foi desabilitado durante a contenção

---

### Passo 7: Pós-Incidente (Postmortem)

**Prazo para postmortem:**
- P0: dentro de 48 horas
- P1: dentro de 1 semana

**Template de postmortem:**

```markdown
# Postmortem: {título do incidente} — {data}

## Resumo
{1-2 parágrafos descrevendo o que aconteceu e o impacto}

## Linha do Tempo
| Hora | Evento |
|------|--------|
| HH:MM | Incidente detectado via {fonte} |
| HH:MM | Notificação enviada ao time |
| HH:MM | Causa raiz identificada |
| HH:MM | Fix deployado |
| HH:MM | Incidente resolvido |

## Causa Raiz
{Descrição técnica detalhada da causa}

## Impacto
- Duração: {X horas Y minutos}
- Clientes afetados: {número ou "todos"}
- Funcionalidades impactadas: {lista}

## O que foi bem
- {o que o time fez certo durante o incidente}

## O que pode melhorar
- {o que não funcionou ou foi lento}

## Itens de Ação
| Item | Responsável | Prazo |
|------|------------|-------|
| {ação preventiva} | {nome} | {data} |

## Lições Aprendidas
{reflexão sobre o que aprendemos}
```

**Salvar postmortem em:** `docs/ops/postmortems/YYYY-MM-DD-titulo.md`

---

## Contatos de Emergência

| Papel | Nome | WhatsApp | Disponibilidade |
|---|---|---|---|
| Engineering Lead (Founder) | Marlow Sousa | +55 XX XXXXX-XXXX | 24/7 para P0 |
| Supabase Support | — | support.supabase.com | Plano pago: 24/7 |
| Vercel Support | — | vercel.com/support | Plano Enterprise: 24/7 |
| DPO (incidentes de dados) | A definir | — | 24/7 para P0 de dados |

---

## Status Page

Manter atualizado durante incidentes públicos:
- **URL**: status.lexendscholar.com (configurar via Better Uptime ou Statuspage.io)
- **Atualizar a cada 30 minutos** durante incidentes P0 e P1
- **Publicar resolução** com breve descrição do problema e solução

---

## Drill de Incidente

Realizar simulação de incidente trimestral:
1. Engineering Lead anuncia um "incidente simulado" sem aviso prévio
2. Time segue este runbook do início ao fim
3. Medir: tempo de detecção, tempo de comunicação, tempo de resolução
4. Registrar aprendizados e atualizar este SOP
