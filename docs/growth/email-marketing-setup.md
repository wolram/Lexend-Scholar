# Email Marketing Setup — MailerLite

Issue: LS-179

## 1. Criação de Conta

1. Acesse [mailerlite.com](https://mailerlite.com) e clique em **Sign Up Free**.
2. Escolha o plano **Free** (até 1.000 contatos e 12.000 emails/mês).
3. Preencha com o email corporativo do Lexend Scholar e confirme via link enviado.
4. Complete o perfil da empresa: nome "Lexend Scholar", endereço físico (obrigatório para compliance CAN-SPAM/LGPD), site `lexendscholar.com`.

---

## 2. Campos Customizados

Acesse **Subscribers → Custom Fields → Add field** e crie os seguintes campos:

| Nome do Campo        | Tipo   | Slug interno          |
|----------------------|--------|-----------------------|
| Nome da Escola       | Text   | `nome_escola`         |
| Plano                | Text   | `plano`               |
| Data de Início Trial | Date   | `data_trial_inicio`   |
| Número de Alunos     | Number | `numero_alunos`       |

> **Plano** deve receber um dos valores: `starter`, `pro`, `enterprise`.

---

## 3. Grupos de Contatos

Acesse **Subscribers → Groups → Add group** e crie:

- **Trials Ativos** — escolas em período de trial (14 dias)
- **Clientes Pagantes Starter** — assinantes ativos do plano Starter
- **Clientes Pagantes Pro** — assinantes ativos do plano Pro
- **Clientes Pagantes Enterprise** — assinantes ativos do plano Enterprise
- **Churned** — ex-clientes que cancelaram a assinatura

---

## 4. Tags

Crie tags para segmentação adicional em **Subscribers → Tags**:

**Por Plano:**
- `plano-starter`
- `plano-pro`
- `plano-enterprise`

**Por Origem do Lead:**
- `origem-organic`
- `origem-ads`
- `origem-indicacao`

---

## 5. Formulário de Captura para o Website

### 5.1 Criação do Formulário

1. Acesse **Forms → Embedded Forms → Create form**.
2. Nome: "Captura Trial Lexend Scholar".
3. Campos: Email (obrigatório), Nome da Escola (obrigatório), Nome do Diretor.
4. Após submit: redirecionar para `/obrigado` com mensagem de confirmação.
5. Adicione ao grupo **Trials Ativos** automaticamente.

### 5.2 Double Opt-In

1. Em **Settings → Double opt-in**, ative a opção.
2. Customize o email de confirmação:
   - Assunto: "Confirme seu acesso ao Lexend Scholar"
   - Corpo: "Clique no botão abaixo para confirmar seu email e iniciar o trial de 14 dias."
3. Página de confirmação: `/trial-confirmado`.

### 5.3 Código de Embed

Após salvar o formulário, copie o snippet gerado pelo MailerLite em **Forms → Get embed code**:

```html
<!-- MailerLite Universal -->
<script>
(function(w,d,e,u,f,l,n){w[f]=w[f]||function(){(w[f].q=w[f].q||[]).push(arguments);},
l=d.createElement(e),l.async=1,l.src=u,n=d.getElementsByTagName(e)[0],
n.parentNode.insertBefore(l,n);})(window,document,'script',
'https://assets.mailerlite.com/js/universal.js','ml');
ml('account', 'SEU_ACCOUNT_ID');
</script>
<!-- End MailerLite Universal -->

<!-- Formulário de Captura -->
<div class="ml-embedded" data-form="SEU_FORM_ID"></div>
```

> Substitua `SEU_ACCOUNT_ID` e `SEU_FORM_ID` pelos valores encontrados no painel do MailerLite.

Cole o snippet na página `/pricing` e na homepage, imediatamente antes do `</body>`.

---

## 6. Automação de Boas-Vindas (Welcome)

Acesse **Automations → Create automation**:

1. **Trigger:** "When a subscriber joins a group" → grupo: **Trials Ativos**
2. **Step 1:** Delay — aguardar **5 minutos**
3. **Step 2:** Send email — selecionar o template "Email 01 — Boas-Vindas"
4. Ative a automação.

Fluxo resumido:

```
[Subscriber joins "Trials Ativos"]
         ↓
   [Wait 5 minutes]
         ↓
[Send: Bem-vindo ao Lexend Scholar!]
```

---

## 7. Integração via API — Adicionar Contato a partir do Webhook Stripe

Quando um cliente completa o checkout no Stripe (evento `checkout.session.completed`), o webhook deve adicionar o contato ao MailerLite.

### 7.1 Obter a API Key

Acesse **Integrations → API → API keys → Create API key**. Copie a chave e salve no `.env`:

```
MAILERLITE_API_KEY=seu_token_aqui
```

### 7.2 Snippet de Integração (Node.js)

```typescript
// lib/mailerlite.ts
import axios from 'axios';

const MAILERLITE_API = 'https://connect.mailerlite.com/api';
const MAILERLITE_KEY = process.env.MAILERLITE_API_KEY!;

// IDs dos grupos (obter no painel MailerLite → Groups)
const GROUPS = {
  trialsAtivos: 'GROUP_ID_TRIALS_ATIVOS',
  starter: 'GROUP_ID_STARTER',
  pro: 'GROUP_ID_PRO',
  enterprise: 'GROUP_ID_ENTERPRISE',
};

interface SubscriberPayload {
  email: string;
  nome_escola: string;
  plano: 'starter' | 'pro' | 'enterprise' | 'trial';
  data_trial_inicio?: string; // ISO 8601
  numero_alunos?: number;
}

export async function addSubscriberToMailerLite(
  payload: SubscriberPayload,
  groupId: string
): Promise<void> {
  await axios.post(
    `${MAILERLITE_API}/subscribers`,
    {
      email: payload.email,
      fields: {
        nome_escola: payload.nome_escola,
        plano: payload.plano,
        data_trial_inicio: payload.data_trial_inicio ?? new Date().toISOString().split('T')[0],
        numero_alunos: payload.numero_alunos ?? 0,
      },
      groups: [groupId],
    },
    {
      headers: {
        Authorization: `Bearer ${MAILERLITE_KEY}`,
        'Content-Type': 'application/json',
      },
    }
  );
}

// Uso no webhook do Stripe:
// pages/api/stripe-webhook.ts (ou app/api/stripe-webhook/route.ts)
//
// case 'checkout.session.completed': {
//   const session = event.data.object as Stripe.Checkout.Session;
//   const metadata = session.metadata ?? {};
//   await addSubscriberToMailerLite(
//     {
//       email: session.customer_details?.email ?? '',
//       nome_escola: metadata.nome_escola,
//       plano: 'trial',
//       data_trial_inicio: new Date().toISOString().split('T')[0],
//       numero_alunos: parseInt(metadata.numero_alunos ?? '0'),
//     },
//     GROUPS.trialsAtivos
//   );
//   break;
// }
```

### 7.3 Mover entre Grupos por Mudança de Plano

```typescript
// Exemplo: ao ativar assinatura Pro
export async function moveSubscriberToGroup(
  email: string,
  fromGroupId: string,
  toGroupId: string
): Promise<void> {
  // 1. Buscar subscriber pelo email
  const res = await axios.get(`${MAILERLITE_API}/subscribers/${encodeURIComponent(email)}`, {
    headers: { Authorization: `Bearer ${MAILERLITE_KEY}` },
  });
  const subscriberId: string = res.data.data.id;

  // 2. Remover do grupo antigo
  await axios.delete(`${MAILERLITE_API}/subscribers/${subscriberId}/groups/${fromGroupId}`, {
    headers: { Authorization: `Bearer ${MAILERLITE_KEY}` },
  });

  // 3. Adicionar ao novo grupo
  await axios.post(
    `${MAILERLITE_API}/subscribers/${subscriberId}/groups`,
    { groups: [toGroupId] },
    { headers: { Authorization: `Bearer ${MAILERLITE_KEY}`, 'Content-Type': 'application/json' } }
  );
}
```

---

## 8. Checklist de Go-Live

- [ ] Conta MailerLite criada e email confirmado
- [ ] Domínio `lexendscholar.com` autenticado (SPF + DKIM) em **Settings → Domains**
- [ ] Campos customizados criados
- [ ] Grupos criados
- [ ] Tags criadas
- [ ] Formulário publicado no website
- [ ] Double opt-in ativado
- [ ] Automação de boas-vindas ativa
- [ ] API key em variável de ambiente
- [ ] Webhook Stripe testado (modo test) com evento `checkout.session.completed`
- [ ] Subscriber de teste aparece no grupo correto no MailerLite
