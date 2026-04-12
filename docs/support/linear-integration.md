# Integração Crisp ↔ Linear — Tickets de Suporte

## Visão Geral

Este documento descreve como configurar a integração entre o Crisp (ferramenta de suporte) e o Linear (gestão de projetos), criando automaticamente issues no Linear quando tickets de suporte relevantes chegam ao Crisp.

**Objetivo**: Garantir rastreabilidade completa entre reportes de clientes e resolução técnica, eliminando duplicação de trabalho e perda de contexto.

---

## Arquitetura do Fluxo

```
Cliente abre chat no Crisp
         ↓
Agente de suporte avalia o ticket
         ↓
É um bug? → Agente adiciona tag "bug" no Crisp
         ↓
Webhook do Crisp dispara para endpoint (Cloudflare Worker / n8n)
         ↓
Middleware cria issue no Linear via GraphQL API
         ↓
Issue criado no Linear com todas as informações do ticket
         ↓
Engineer resolve o bug
         ↓
Linear issue fechado → Webhook do Linear fecha ticket no Crisp
```

---

## Configuração do Webhook no Crisp

### 1. Acessar configurações de webhooks
1. No dashboard Crisp, acesse **Settings > Integrations > Webhooks**
2. Clique em **Add a webhook endpoint**
3. Configure a URL do endpoint (ver seção "Middleware" abaixo)

### 2. Eventos a subscrever
Selecione os seguintes eventos:

```
message:send          → Novos tickets criados
conversation:resolved → Ticket resolvido
conversation:updated  → Mudança de tags (para detectar tag "bug")
```

### 3. Payload de exemplo — conversation:updated (tag adicionada)

```json
{
  "website_id": "abc123",
  "event": "conversation:updated",
  "timestamp": 1704891600,
  "data": {
    "conversation_id": "session::abc123::xyz789",
    "meta": {
      "nickname": "Maria Silva",
      "email": "diretora@escolaexemplo.com.br",
      "segments": ["bug", "pro"],
      "data": {
        "school_id": "escola_456",
        "plan": "pro",
        "students_count": "320"
      }
    },
    "messages": [
      {
        "content": "Não consigo lançar frequência, dá erro ao salvar",
        "from": "user",
        "timestamp": 1704891500
      },
      {
        "content": "Obrigado pelo reporte! Vou criar um ticket técnico.",
        "from": "operator",
        "timestamp": 1704891580
      }
    ]
  }
}
```

---

## Middleware — Cloudflare Worker

Crie um Cloudflare Worker (`crisp-to-linear`) para processar os webhooks:

```javascript
// crisp-to-linear/index.js
export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    const payload = await request.json();

    // Verificar assinatura do Crisp (segurança)
    const signature = request.headers.get('X-Crisp-Signature');
    if (!verifySignature(payload, signature, env.CRISP_WEBHOOK_SECRET)) {
      return new Response('Invalid signature', { status: 401 });
    }

    // Processar apenas quando tag "bug" é adicionada
    const isBugTagged = payload.data?.meta?.segments?.includes('bug');
    if (!isBugTagged || payload.event !== 'conversation:updated') {
      return new Response('OK', { status: 200 });
    }

    // Verificar se issue já existe (evitar duplicatas)
    const conversationId = payload.data.conversation_id;
    const existingIssue = await checkExistingLinearIssue(conversationId, env);
    if (existingIssue) {
      return new Response('Issue already exists', { status: 200 });
    }

    // Criar issue no Linear
    const linearIssue = await createLinearIssue(payload, env);

    // Adicionar comentário no Crisp com link do Linear
    await addCrispComment(
      conversationId,
      `Issue criado no Linear: ${linearIssue.url}`,
      env
    );

    return new Response(JSON.stringify({ linearIssueId: linearIssue.id }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};

async function createLinearIssue(payload, env) {
  const { data } = payload;
  const clientEmail = data.meta?.email || 'desconhecido';
  const clientName = data.meta?.nickname || 'Cliente';
  const plan = data.meta?.data?.plan || 'basic';
  const schoolId = data.meta?.data?.school_id || '';
  const lastMessage = data.messages?.[0]?.content || '';
  const conversationId = data.conversation_id;
  const crispUrl = `https://app.crisp.chat/website/${env.CRISP_WEBSITE_ID}/inbox/${conversationId}`;

  // Mapear plano para label de prioridade
  const priorityMap = { enterprise: 1, pro: 2, basic: 3 };
  const priority = priorityMap[plan] || 3;

  const mutation = `
    mutation CreateIssue($input: IssueCreateInput!) {
      issueCreate(input: $input) {
        issue {
          id
          identifier
          url
        }
      }
    }
  `;

  const variables = {
    input: {
      teamId: env.LINEAR_TEAM_ID, // ID do time Lexend Scholar
      title: `[Bug] ${lastMessage.substring(0, 80)}`,
      description: `## Reporte de Bug via Suporte

**Cliente**: ${clientName} (${clientEmail})
**Plano**: ${plan.toUpperCase()}
**Escola ID**: ${schoolId}

**Descrição do problema**:
${lastMessage}

**Ticket no Crisp**: [Abrir conversa](${crispUrl})
**Conversation ID**: \`${conversationId}\`

---
*Issue criado automaticamente via integração Crisp → Linear*`,
      priority: priority,
      labelIds: [env.LINEAR_LABEL_BUG_ID],
      stateId: env.LINEAR_STATE_TRIAGE_ID
    }
  };

  const response = await fetch('https://api.linear.app/graphql', {
    method: 'POST',
    headers: {
      'Authorization': env.LINEAR_API_KEY,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ query: mutation, variables })
  });

  const result = await response.json();
  return result.data.issueCreate.issue;
}
```

### Variáveis de ambiente do Worker

```env
CRISP_WEBHOOK_SECRET=<secret gerado no Crisp>
CRISP_WEBSITE_ID=<website ID do Crisp>
CRISP_API_KEY=<API key do Crisp>
LINEAR_API_KEY=lin_api_...
LINEAR_TEAM_ID=740589b4-a4b2-47e9-9807-7065c4377fa1
LINEAR_LABEL_BUG_ID=<ID do label Bug no Linear>
LINEAR_STATE_TRIAGE_ID=<ID do state Triage no Linear>
```

---

## Template do Issue Criado no Linear

```
Título: [Bug] <primeiros 80 chars da mensagem do cliente>

Labels: Bug, P1/P2/P3 (baseado no plano), Needs Review
Assignee: (nenhum — entra no Triage)
State: Triage

Body:
## Reporte de Bug via Suporte

**Cliente**: Maria Silva (diretora@escolaexemplo.com.br)
**Plano**: PRO
**Escola ID**: escola_456

**Descrição do problema**:
Não consigo lançar frequência, dá erro ao salvar. Acontece sempre
que clico em "Salvar" na tela de frequência da turma 3A.

**Ticket no Crisp**: [Abrir conversa](https://app.crisp.chat/...)
**Conversation ID**: `session::abc123::xyz789`

---
*Issue criado automaticamente via integração Crisp → Linear*
```

---

## Workflow Completo: Crisp → Linear → Resolve → Fecha Ticket

### Fase 1: Reporte (Crisp)
1. Cliente envia mensagem descrevendo o bug
2. Agente reproduz e confirma o bug
3. Agente adiciona tag **`bug`** na conversa do Crisp
4. Webhook dispara automaticamente
5. Issue criado no Linear (state: **Triage**)
6. Comentário automático no Crisp: "Issue LS-XXX criado no Linear"

### Fase 2: Triagem e Desenvolvimento (Linear)
1. Engineer de plantão faz triage diária (09h30 BRT)
2. Issue movido para **In Progress** com engineer assignado
3. Engineer adiciona comentário no Linear com análise
4. Comentário sincronizado para o Crisp via webhook reverso (opcional)

### Fase 3: Resolução (Linear → Crisp)
Quando o issue no Linear é fechado como **Done**:

```javascript
// Webhook do Linear → fecha ticket no Crisp
// Configurar em Linear > Settings > API > Webhooks

async function onLinearIssueDone(payload) {
  if (payload.type !== 'Issue' || payload.action !== 'update') return;
  if (payload.data.state.type !== 'completed') return;

  const description = payload.data.description;
  const match = description.match(/Conversation ID.*`(session::[^`]+)`/);
  if (!match) return;

  const conversationId = match[1];

  // Adicionar nota de resolução no Crisp
  await crispClient.website.sendMessageInConversation(
    CRISP_WEBSITE_ID,
    conversationId,
    {
      type: 'text',
      content: `Boa notícia! O problema que você reportou foi corrigido e a correção está disponível na versão ${payload.data.title.match(/v[\d.]+/)?.[0] || 'mais recente'}. Por favor, atualize o app e nos avise se o problema persistir.`,
      from: 'operator',
      origin: 'chat'
    }
  );

  // Resolver o ticket no Crisp
  await crispClient.website.resolveConversation(CRISP_WEBSITE_ID, conversationId);
}
```

### Resumo do Fluxo de States

```
Crisp: OPEN → Linear: TRIAGE → Linear: IN PROGRESS → Linear: DONE → Crisp: RESOLVED
```

---

## Configuração via n8n (Alternativa sem código)

Para equipes sem capacidade de deploy de workers, o n8n pode substituir o Cloudflare Worker:

1. **Trigger**: Webhook node (URL fornecida ao Crisp)
2. **Filter**: IF node → verificar se `data.meta.segments` contém "bug"
3. **HTTP Request**: Criar issue no Linear via GraphQL
4. **HTTP Request**: Comentar no Crisp com link do issue

Template de workflow disponível em: `docs/ops/n8n-crisp-linear.json` (a criar)

---

## Monitoramento da Integração

- Verificar logs do Worker em Cloudflare Dashboard diariamente
- Criar alerta se webhook falhar 3x seguidas (Dead Letter Queue)
- Revisar tickets sem issue no Linear semanalmente (auditoria manual)
- KPI: % de tickets com bug que geram issue no Linear (meta: 100%)
