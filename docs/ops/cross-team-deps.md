# Cross-Team Dependencies — Lexend Scholar

**Versão**: 1.0
**Owner**: Operações / Engineering Lead
**Última atualização**: Abril 2026

---

## Visão Geral

Em um workspace com múltiplos projetos (Lexend Scholar — LS, Concurseiro PRO — CONC, BrainStormAI — BSAI), é comum que um time precise de algo de outro time para progredir. Este documento define como mapear, comunicar e resolver dependências cross-team no Linear.

---

## O que é uma Dependência Cross-Team

Uma dependência cross-team existe quando:
- Time A não pode completar uma issue SEM que o Time B faça algo primeiro
- Time A precisa de uma decisão, recurso, API ou componente do Time B
- Times A e B estão trabalhando em algo que se integra e precisam coordenar

**Exemplos de dependências LS com outros times:**

| Issue LS | Depende de | Time |
|---|---|---|
| Integrar autenticação SSO com Concurseiro PRO | Expor endpoint de OAuth no CONC | CONC |
| Usar modelo de IA para análise de desempenho | API de predição pronta | BSAI |
| Infraestrutura compartilhada de banco | Configuração de Supabase multi-tenant | DevOps |
| Design system compartilhado | Tokens de design exportados | Design |

---

## Como Mapear Dependências no Linear

### 1. Usar a feature nativa de "Relations" do Linear

O Linear suporta relações entre issues de times diferentes:

- **Blocks**: "Esta issue BLOQUEIA a outra" — a outra não pode avançar até esta estar resolvida
- **Blocked by**: "Esta issue É BLOQUEADA pela outra" — somos os dependentes
- **Related to**: "Estas issues são relacionadas" — informacional, sem bloqueio duro

**Como adicionar:**
1. Abrir a issue no Linear
2. Clicar em **"Add relation"** (ícone de link na barra lateral direita)
3. Selecionar o tipo: Blocks / Blocked by / Related to / Duplicate of
4. Buscar e selecionar a issue do outro time

### 2. Adicionar label `Blocked` + comentário

Quando sua issue está bloqueada:
1. Adicionar label `Blocked` (ver `linear-labels.md`)
2. Adicionar comentário explicando:
   - **O que está bloqueado**: Descrição clara
   - **O que precisamos**: A entrega específica esperada do outro time
   - **Quem é o contato**: @menção da pessoa no outro time
   - **Prazo**: Quando precisamos para não atrasar nosso sprint

**Template de comentário para issue bloqueada:**
```
🔴 BLOQUEADO — Aguardando Team CONC

**O que está bloqueado**: Não podemos implementar o SSO do Lexend Scholar até ter o endpoint OAuth do Concurseiro PRO.

**O que precisamos**: Endpoint POST /oauth/token que aceite client_credentials e retorne JWT com claims de usuário.

**Contato no time CONC**: @nome-do-responsavel

**Impacto se não resolvido até {data}**: LS-XXX atrasa 1 sprint, bloqueando o onboarding de escolas piloto.

**Issue correspondente no CONC**: CONC-XXX
```

---

## Template de Issue de Dependência

Quando você precisa criar uma issue em outro time para solicitar algo:

### Template para criar no time receptor (ex: CONC)

```markdown
Título: [Cross-team] Expor endpoint OAuth para integração com Lexend Scholar

**Solicitante**: Time Lexend Scholar (LS)
**Contato**: @marlow
**Issue relacionada no LS**: LS-XXX

## Contexto
O Lexend Scholar precisa de autenticação SSO com o Concurseiro PRO para permitir
que usuários de um produto acessem o outro sem login separado.

## O que precisamos

Endpoint: POST /oauth/v2/token
Auth: client_credentials grant type
Parâmetros:
- client_id: ID fornecido pelo time LS
- client_secret: Secret compartilhado
- scope: profile email

Resposta esperada:
{
  "access_token": "JWT_TOKEN",
  "token_type": "Bearer",
  "expires_in": 3600,
  "user": {
    "id": "uuid",
    "email": "usuario@email.com",
    "name": "Nome do Usuário"
  }
}

## Por que precisamos disso
Escolas com professores que também usam Concurseiro PRO precisam de SSO.

## Quando precisamos
**Prazo**: {data} — para inclusão no sprint de {mês}

## Notas adicionais
{qualquer contexto técnico adicional}
```

---

## Processo de Resolução de Bloqueios

### Passo a Passo

**1. Identificação (imediata)**
- Engenheiro identifica que está bloqueado por outro time
- Adiciona label `Blocked` na issue
- Adiciona comentário com template acima

**2. Comunicação (dentro de 24h)**
- Notificar a pessoa de contato no outro time via Slack (canal do time ou DM)
- Mensagem modelo:
  ```
  Olá @nome! 

  O time do Lexend Scholar está bloqueado na issue LS-XXX e precisamos de vocês.
  Criei a issue CONC-XXX com os detalhes do que precisamos.
  Consegue dar uma olhada e nos dar uma estimativa de quando pode ser entregue?

  Impacto para nós: [descrever brevemente]
  ```

**3. Alinhamento (dentro de 48h)**
- Responsável no time receptor confirma se pode atender
- Se sim: estima prazo e cria/prioriza a issue em seu backlog
- Se não pode atender no prazo: escalar para líderes de produto

**4. Escalação (se não resolvido em 48h)**
- Escalar para os founders / leads dos dois times
- Reunião de alinhamento de 30 minutos para definir priorização
- Decisão documentada no comentário das issues envolvidas

**5. Resolução**
- Quando o bloqueio é resolvido, remover label `Blocked`
- Adicionar comentário de resolução com link da entrega do outro time
- Atualizar a issue com as informações recebidas

---

## Canais de Comunicação por Time

| Time | Canal Slack | Lead |
|---|---|---|
| Lexend Scholar (LS) | #lexend-scholar | Marlow Sousa |
| Concurseiro PRO (CONC) | #concurseiro-pro | (definir) |
| BrainStormAI (BSAI) | #brainstorm-ai | (definir) |
| DevOps / Infrastructure | #devops | (definir) |
| Design | #design | (definir) |

---

## Reunião de Sincronização Cross-Team

### Formato recomendado: Bi-semanal, 30 minutos

**Participantes**: Leads de cada time com dependências ativas

**Pauta**:
1. Review de dependências bloqueadas (10 min)
2. Novas dependências identificadas (10 min)
3. Priorização e negociação (10 min)

**Documento de acompanhamento**: Criar issue recorrente no Linear com lista de dependências ativas.

---

## Dashboard de Dependências Cross-Team

Para visualizar todas as dependências ativas:

**No Linear:**
1. Ir em **Views → New view**
2. Filtrar por: Label = `Blocked`
3. Agrupar por: Team
4. Salvar como: "Cross-team Blockers"

**Filtro adicional útil**: Issues com relação "Blocked by" em outro time

---

## Exemplo Real: LS × BSAI

**Cenário**: LS quer adicionar "Análise de risco de evasão" baseada em ML no dashboard do diretor.

**Fluxo de dependência:**

```
[LS-XXX] Dashboard de risco de evasão
      ↓ (blocked by)
[BSAI-YYY] API de predição de evasão escolar
      ↓ (precisa de)
Dados históricos de frequência para treinar o modelo
      ↓ (fornecido por)
[LS-ZZZ] Exportar dataset anônimo de frequência para BSAI
```

**Comunicação:**
1. Time LS abre BSAI-YYY com template de dependência
2. Time BSAI avalia viabilidade e estima 2 sprints
3. Time LS planeja LS-XXX para o sprint posterior ao BSAI-YYY
4. Time LS provisiona LS-ZZZ para fornecer os dados ao BSAI

---

## Anti-patterns a Evitar

**Não faça:**
- Iniciar desenvolvimento assumindo que o outro time vai entregar no prazo sem confirmar
- Criar dependências sem comunicar ao outro time
- Deixar issues bloqueadas sem atualização por mais de 3 dias
- Criar dependências circulares (A depende de B que depende de A)
- Escalar por email — usar sempre o Linear + Slack para rastreabilidade

**Faça:**
- Comunicar dependências o mais cedo possível
- Ter uma conversa de alinhamento antes de criar issues formais
- Documentar decisões nos comentários das issues
- Celebrar quando dependências são resolvidas
