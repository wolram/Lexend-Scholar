# Programa de Indicação Escola-para-Escola

Issue: LS-186

---

## Visão Geral

O programa de indicação do Lexend Scholar permite que escolas clientes indiquem outras escolas e ganhem créditos em suas assinaturas. O incentivo é simples e de alto valor percebido: **1 mês grátis por escola indicada que permanecer ativa por 30 dias**.

---

## Mecânica do Programa

### Para a Escola Indicante

- Cada escola ativa recebe um **link único de indicação**: `https://lexendscholar.com/indica?ref=ESCOLA_ID`
- Quando uma escola indicada ativa a assinatura e permanece por **30 dias consecutivos**, a escola indicante recebe **1 mês gratuito** na renovação seguinte.
- Não há limite de indicações — quanto mais escolas indicar, mais meses gratuitos acumula.
- Os créditos são aplicados automaticamente na próxima fatura (via Stripe).

### Para a Escola Indicada

- Acessa o sistema normalmente pelo link de referral.
- Recebe o trial padrão de 14 dias.
- Não há custo adicional ou obrigação além do trial normal.

---

## Landing Page de Indicação

**URL:** `https://lexendscholar.com/indica?ref={{escola_id}}`

### Conteúdo da Landing Page

**Headline:** "O [Nome da Escola] indicou o Lexend Scholar para você"

**Subtítulo:** "Teste grátis por 14 dias — sem cartão de crédito"

**Benefícios destacados (3 bullets):**
- Frequência digital em 3 cliques
- Boletim gerado em 1 clique com a logo da sua escola
- Financeiro integrado com Pix e boleto

**Formulário simples:**

| Campo               | Tipo     | Obrigatório |
|---------------------|----------|-------------|
| Nome da escola      | Text     | Sim         |
| Email do diretor    | Email    | Sim         |
| Telefone (WhatsApp) | Tel      | Não         |

**CTA:** "Iniciar meu trial gratuito →"

Após o submit, salvar o `referrer_school_id` na sessão e associar ao novo cadastro.

---

## Schema SQL

```sql
-- Tabela de indicações
CREATE TABLE referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_school_id UUID REFERENCES schools(id),
  referred_school_id UUID REFERENCES schools(id),
  status TEXT DEFAULT 'pending', -- pending | active | rewarded
  created_at TIMESTAMPTZ DEFAULT NOW(),
  activated_at TIMESTAMPTZ,       -- quando a escola indicada ativou a assinatura
  reward_applied_at TIMESTAMPTZ   -- quando o crédito foi aplicado na fatura
);

-- Tabela de créditos acumulados
CREATE TABLE referral_credits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID REFERENCES schools(id),
  months_credit INTEGER DEFAULT 1,
  applied_at TIMESTAMPTZ,
  subscription_period_start TIMESTAMPTZ
);

-- Índices para queries frequentes
CREATE INDEX idx_referrals_referrer ON referrals (referrer_school_id);
CREATE INDEX idx_referrals_referred ON referrals (referred_school_id);
CREATE INDEX idx_referrals_status ON referrals (status);
CREATE INDEX idx_referral_credits_school ON referral_credits (school_id);
```

---

## Fluxo de Aprovação do Crédito

```
Escola B se cadastra via link da Escola A
           ↓
  [referrals] criado com status = 'pending'
           ↓
Escola B ativa assinatura paga
           ↓
  [referrals] status → 'active'
  activated_at = NOW()
           ↓
  CRON: verificar daily se activated_at + 30 dias ≤ NOW()
  AND assinatura ainda ativa
           ↓
  [referrals] status → 'rewarded'
  reward_applied_at = NOW()
           ↓
  [referral_credits] criado: months_credit = 1 para Escola A
           ↓
  Stripe: aplicar crédito na próxima fatura da Escola A
```

### Implementação do CRON (Supabase Edge Function)

```typescript
// supabase/functions/process-referral-rewards/index.ts
import { createClient } from '@supabase/supabase-js';
import Stripe from 'stripe';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
);

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2024-06-20',
});

Deno.serve(async () => {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  // Buscar indicações ativas há mais de 30 dias, ainda não recompensadas
  const { data: referrals } = await supabase
    .from('referrals')
    .select('*, referrer_school:schools!referrer_school_id(stripe_customer_id)')
    .eq('status', 'active')
    .lt('activated_at', thirtyDaysAgo.toISOString());

  for (const referral of referrals ?? []) {
    // Aplicar crédito de 1 mês no Stripe
    const stripeCustomerId = referral.referrer_school.stripe_customer_id;
    const priceAmount = await getSchoolMonthlyPrice(referral.referrer_school_id);

    await stripe.customers.createBalanceTransaction(stripeCustomerId, {
      amount: -priceAmount, // negativo = crédito
      currency: 'brl',
      description: `Crédito de indicação — escola #${referral.referred_school_id}`,
    });

    // Atualizar status da indicação
    await supabase
      .from('referrals')
      .update({ status: 'rewarded', reward_applied_at: new Date().toISOString() })
      .eq('id', referral.id);

    // Registrar crédito
    await supabase.from('referral_credits').insert({
      school_id: referral.referrer_school_id,
      months_credit: 1,
      applied_at: new Date().toISOString(),
    });
  }

  return new Response(JSON.stringify({ processed: referrals?.length ?? 0 }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
```

---

## Emails Automáticos

### Email 1 — Confirmação de Indicação (para a escola indicante)

**Assunto:** "Sua indicação foi registrada! 🎉"

**Corpo:** "A escola [Nome da Escola Indicada] se cadastrou usando seu link. Assim que ela ativar a assinatura e completar 30 dias, você ganha 1 mês grátis automaticamente. Vamos te avisar por email."

---

### Email 2 — Notificação de Ativação (para a escola indicante)

**Assunto:** "A escola que você indicou ativou a assinatura — você está perto do seu mês grátis!"

**Corpo:** "A escola [Nome da Escola Indicada] ativou a assinatura. Faltam apenas 30 dias de permanência para você receber 1 mês gratuito. Continuaremos monitorando e te avisamos quando o crédito for aplicado."

---

### Email 3 — Confirmação do Crédito (para a escola indicante)

**Assunto:** "Seu mês grátis foi aplicado! ✅"

**Corpo:** "Boa notícia: o crédito referente à sua indicação da escola [Nome da Escola Indicada] foi aplicado na sua conta. Seu próximo mês está garantido sem custo. Quer indicar mais uma escola e ganhar mais meses? Aqui está o seu link: [link único]"

---

## Kit de Divulgação

### Texto para WhatsApp (da diretora para contatos)

> Oi! Queria te recomendar um sistema que mudou a gestão da nossa escola. Chama Lexend Scholar — a gente controla frequência, notas e financeiro tudo em um app. Muito mais fácil do que planilha e lista de chamada em papel.
>
> Você pode testar grátis por 14 dias, sem cartão de crédito, pelo link:
> 👉 https://lexendscholar.com/indica?ref={{escola_id}}
>
> Se tiver dúvida, me chama que te conto como funciona aqui na nossa escola!

---

### Email para Diretora Enviar a Colegas

**Assunto:** "Sistema de gestão escolar que recomendo (com 14 dias grátis)"

**Corpo:**

Olá,

Queria compartilhar uma ferramenta que tem transformado a rotina aqui no [Nome da Escola].

Usamos o Lexend Scholar para controlar frequência, lançar notas, gerar boletins e gerenciar as mensalidades — tudo em um só lugar, no celular ou no computador.

O que mais gostei foi a facilidade de implementação: em 3 dias estávamos funcionando completamente. A secretaria parou de usar planilhas e os professores fazem a chamada pelo celular.

Você pode testar gratuitamente por 14 dias (sem precisar colocar cartão de crédito) por este link:

https://lexendscholar.com/indica?ref={{escola_id}}

Qualquer dúvida, me avisa!

Abraços,
[Nome da Diretora]
[Nome da Escola]
