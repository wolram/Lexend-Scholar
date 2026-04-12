# Campanha Google Ads — Lexend Scholar

Issue: LS-183

---

## Visão Geral

| Campo                  | Valor                                       |
|------------------------|---------------------------------------------|
| **Nome da campanha**   | Lexend Scholar — Search — Brasil            |
| **Tipo**               | Search (Rede de Pesquisa)                   |
| **Budget mensal**      | R$ 1.500,00                                 |
| **CPC máximo**         | R$ 3,00                                     |
| **Estratégia de lances** | CPA desejado → Meta: CPA < R$ 400,00     |
| **Localização**        | Brasil — todas as regiões                   |
| **Idioma**             | Português                                   |
| **Conversão principal** | Signup de trial (evento `trial_signup`)    |

---

## KPIs e Metas

| KPI                     | Meta        |
|-------------------------|-------------|
| CTR                     | > 5%        |
| Taxa de conversão trial | > 8%        |
| CAC (via Google Ads)    | < R$ 400,00 |
| Impressões / mês        | > 20.000    |
| Cliques / mês           | > 1.000     |

---

## Estrutura de Grupos de Anúncios

### Grupo 1 — Software Gestão Escolar

**Tipo de correspondência:** Exata (Exact Match)

**Keywords:**
```
[sistema de gestão escolar]
[software escola]
[programa para escola]
[sistema escolar]
[software de gestão escolar]
```

**Anúncio RSA (Responsive Search Ad):**

_Headlines (até 15):_
1. Gestão Escolar Completa
2. Frequência e Boletim Digital
3. 14 Dias Grátis Sem Cartão
4. Software Para Sua Escola
5. Controle Total da Sua Escola
6. Notas e Frequência em 1 App
7. Experimente Grátis 14 Dias
8. Simples, Rápido e Completo
9. Substitua o Papel e as Planilhas
10. Gestão Escolar no Celular

_Descriptions (até 4):_
1. Controle frequência, notas e financeiro da sua escola em um app. Teste grátis por 14 dias — sem cartão de crédito.
2. Mais de 200 escolas já usam o Lexend Scholar. Fácil de usar, sem necessidade de treinamento. Comece hoje.
3. Importe sua lista de alunos em minutos. Frequência digital, boletim em 1 clique e cobranças automáticas.
4. Migração gratuita do seu sistema atual. Suporte em português de segunda a sexta. Trial de 14 dias sem custo.

**URL Final:** `https://app.lexendscholar.com/trial`
**URL de Display:** `lexendscholar.com/trial`

---

### Grupo 2 — App Escola

**Tipo de correspondência:** Broad Match Modifier

**Keywords:**
```
+app +escola
+aplicativo +gestão +escolar
+app +gestão +escola
+aplicativo +escola +gratuito
+app +controle +alunos
```

_Headlines:_
1. App de Gestão Escolar
2. Gerencie Sua Escola pelo Celular
3. App Para Diretores e Secretarias
4. iOS e Android — Grátis por 14 Dias
5. App Escolar Completo

_Descriptions:_
1. App para iOS e Android com frequência digital, notas, boletins e financeiro integrado. Sem papel, sem planilha.
2. Professores fazem a chamada no celular. Pais recebem notificação automática. Diretores veem tudo em tempo real.

**URL Final:** `https://app.lexendscholar.com/trial`

---

### Grupo 3 — Diário de Classe Digital

**Tipo de correspondência:** Frase (Phrase Match) e Long Tail

**Keywords:**
```
"diário de classe digital"
"controle de presença alunos app"
"sistema de frequência escolar"
"como fazer chamada digital"
"substituir lista de chamada papel"
"app frequência alunos"
"registro de presença digital escola"
"diário eletrônico escolar"
```

_Headlines:_
1. Diário de Classe Digital
2. Adeus Lista de Chamada em Papel
3. Frequência em 3 Cliques
4. Chamada Digital Para Professores
5. Relatório de Frequência Automático

_Descriptions:_
1. Substitua a lista de chamada em papel por frequência digital. Professores registram em 3 cliques. Relatório automático para os pais.
2. Diário de classe digital com relatório mensal gerado automaticamente. Notificação de falta enviada para os responsáveis na hora.

**URL Final:** `https://app.lexendscholar.com/features/attendance`

---

### Grupo 4 — Concorrentes (Conquista)

**Tipo de correspondência:** Exata e Frase

**Keywords:**
```
"alternativa ao [sistema concorrente]"
"[sistema concorrente] alternativa"
"trocar de sistema escolar"
"migrar sistema de gestão escolar"
"melhor que [sistema concorrente]"
```

> Nota: substituir `[sistema concorrente]` pelos nomes dos principais sistemas identificados na pesquisa competitiva. Manter conformidade com as políticas do Google Ads para marcas de terceiros.

_Headlines:_
1. Cansou do Seu Sistema Atual?
2. Migração Gratuita Garantida
3. Troque em 3 Dias — Sem Dor de Cabeça
4. Suporte em Português, Sempre
5. Mais Simples. Mais Barato.

_Descriptions:_
1. Migração gratuita do seu sistema atual. Nossa equipe faz tudo por você em até 3 dias. Trial de 14 dias sem cartão.
2. Não perca seus dados. Migramos histórico de alunos, notas e frequências. Comece a testar agora, sem compromisso.

**URL Final:** `https://app.lexendscholar.com/trial?utm_source=google&utm_campaign=concorrentes`

---

## Configuração de Conversão

### Via Google Tag Manager

1. Criar tag **GA4 Event** com o evento `trial_signup`.
2. Disparar quando o usuário acessar a URL `/trial-confirmado` (página de sucesso após signup).
3. Publicar o container GTM.

### Via Stripe Webhook

No webhook `checkout.session.completed`, disparar o evento de conversão do Google Ads via API:

```typescript
// Após confirmar o signup de trial:
// 1. Enviar para o dataLayer (se GTM no client-side):
// window.dataLayer.push({ event: 'trial_signup', value: 0, currency: 'BRL' });

// 2. Ou via Conversions API (server-side) com a biblioteca google-ads-api:
import { GoogleAdsApi, enums } from 'google-ads-api';

async function reportTrialConversion(orderId: string, conversionTime: string) {
  const client = new GoogleAdsApi({
    client_id: process.env.GOOGLE_ADS_CLIENT_ID!,
    client_secret: process.env.GOOGLE_ADS_CLIENT_SECRET!,
    developer_token: process.env.GOOGLE_ADS_DEVELOPER_TOKEN!,
  });

  const customer = client.Customer({
    customer_id: process.env.GOOGLE_ADS_CUSTOMER_ID!,
    refresh_token: process.env.GOOGLE_ADS_REFRESH_TOKEN!,
  });

  await customer.conversionUploads.uploadClickConversions({
    customer_id: process.env.GOOGLE_ADS_CUSTOMER_ID!,
    conversions: [
      {
        gclid: orderId, // Google Click ID capturado no momento do signup
        conversion_action: `customers/${process.env.GOOGLE_ADS_CUSTOMER_ID}/conversionActions/CONVERSION_ACTION_ID`,
        conversion_date_time: conversionTime, // formato: '2026-04-12 10:00:00-03:00'
        conversion_value: 0,
        currency_code: 'BRL',
      },
    ],
    partial_failure: true,
  });
}
```

> Importante: capturar e armazenar o `gclid` (Google Click ID) da URL no momento em que o usuário acessa a landing page de trial. Salvar no banco junto com o `school_id`.

---

## Extensões de Anúncio

| Tipo            | Conteúdo                                                  |
|-----------------|-----------------------------------------------------------|
| Sitelinks       | "Ver Planos e Preços", "Como Funciona", "Falar com Suporte", "Depoimentos" |
| Callout         | "14 Dias Grátis", "Sem Cartão de Crédito", "Suporte em Português", "Migração Gratuita" |
| Estruturado     | Cabeçalho: "Módulos" — Valores: Frequência, Notas, Financeiro, Comunicação, Boletim |
| Chamada         | Número de telefone comercial do Lexend Scholar            |

---

## Segmentação Negativa

Adicionar as seguintes palavras-chave negativas na campanha:

```
gratuito para sempre
grátis para sempre
open source
código aberto
freelancer
emprego
vaga
```

---

## Calendário de Otimização

| Frequência | Ação                                                     |
|------------|----------------------------------------------------------|
| Diária     | Verificar gastos x orçamento, pausar palavras-chave com CTR < 1% |
| Semanal    | Analisar Search Terms Report, adicionar negativos        |
| Quinzenal  | Testar novos headlines, comparar variantes de RSA        |
| Mensal     | Revisar CPA vs. meta, ajustar lances por grupo           |
