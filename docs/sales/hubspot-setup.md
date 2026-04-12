# HubSpot CRM — Setup Completo

Issue: LS-146

---

## 1. Criação de Conta

1. Acesse [hubspot.com](https://hubspot.com) e clique em **Get started free**.
2. Use o email corporativo do Lexend Scholar.
3. Configure a empresa: nome "Lexend Scholar", segmento "Software/SaaS", país "Brasil".
4. Selecione o plano **Free** (suficiente para o estágio atual — até 1.000.000 de contatos, pipeline ilimitado).

---

## 2. Pipeline de Vendas — 8 Etapas

Acesse **CRM → Deals → Pipelines → Customize pipelines → Create pipeline** e nomeie "Pipeline Lexend Scholar".

Crie as seguintes etapas na ordem:

| # | Nome da Etapa        | Probabilidade | Descrição                                            |
|---|----------------------|---------------|------------------------------------------------------|
| 1 | Prospect             | 5%            | Escola identificada, ainda sem contato realizado     |
| 2 | Contato Inicial      | 15%           | Email ou LinkedIn enviado, aguardando resposta       |
| 3 | Demo Agendada        | 30%           | Reunião de demo confirmada no calendário             |
| 4 | Demo Realizada       | 45%           | Demo concluída, interesse confirmado pelo decisor    |
| 5 | Proposta Enviada     | 60%           | Proposta/contrato enviado formalmente                |
| 6 | Negociação           | 75%           | Em negociação ativa (preço, prazo, condições)        |
| 7 | Fechado Ganho        | 100%          | Contrato assinado, trial ou pagamento iniciado       |
| 8 | Fechado Perdido      | 0%            | Negócio perdido — registrar motivo obrigatoriamente  |

---

## 3. Propriedades Customizadas

Acesse **Settings → Properties → Deals → Create property** e crie as 9 propriedades:

| Nome da Propriedade | Tipo de Campo | Valores/Formato                              |
|---------------------|---------------|----------------------------------------------|
| `numero_alunos`     | Number        | Inteiro positivo                             |
| `plano_interesse`   | Dropdown      | Starter / Pro / Enterprise / A Definir       |
| `sistema_atual`     | Text          | Nome do sistema que a escola usa atualmente  |
| `decisor_nome`      | Text          | Nome completo do decisor                     |
| `decisor_cargo`     | Dropdown      | Diretor / Proprietário / Coordenador / Financeiro / TI |
| `data_demo`         | Date          | Data agendada para a demo                    |
| `proposta_valor`    | Currency (BRL)| Valor mensal proposto                        |
| `motivo_perda`      | Dropdown      | Preço / Concorrente / Não tem budget agora / Projeto cancelado / Sem resposta / Outro |
| `proximos_passos`   | Long text     | Próximas ações acordadas com o prospect      |

---

## 4. Views (Visões Salvas)

Acesse **CRM → Deals → All deals → Add filter** e salve as seguintes views:

### View 1 — Pipeline Ativo
- Filtro: Etapa NÃO É "Fechado Ganho" E NÃO É "Fechado Perdido"
- Ordenação: Data de criação (mais recente)
- Colunas: Nome da Escola, Etapa, Valor, Decisor Nome, Data da Demo, Próximos Passos

### View 2 — Demos Esta Semana
- Filtro: `data_demo` está entre hoje e próximos 7 dias
- Ordenação: `data_demo` ascendente
- Colunas: Nome da Escola, Data Demo, Decisor Nome, Plano Interesse, Número de Alunos

### View 3 — Propostas Abertas
- Filtro: Etapa É "Proposta Enviada" OU "Negociação"
- Ordenação: `proposta_valor` descendente
- Colunas: Nome da Escola, Proposta Valor, Plano Interesse, Data da última atividade

### View 4 — Fechados Este Mês
- Filtro: Etapa É "Fechado Ganho", Data de fechamento no mês atual
- Ordenação: Valor descendente
- Colunas: Nome da Escola, Plano Interesse, Proposta Valor, Decisor Nome

---

## 5. Automações

### Automação 1 — Mover para "Demo Agendada" ao Criar Reunião

**Trigger:** Reunião criada e associada a um deal  
**Ação:** Mover deal para a etapa "Demo Agendada"  
**Configuração:** Acesse **Workflows → Create workflow → Deal-based**  
- Trigger: Meeting created associated with this deal  
- Action: Set deal property → Deal Stage = "Demo Agendada"

### Automação 2 — Lembrete 24h Antes da Demo

**Trigger:** 24 horas antes da data/hora da reunião  
**Ação:** Enviar notificação interna para o dono do deal  
**Mensagem:** "Lembrete: demo com {{company.name}} amanhã às {{meeting.start_time}}. Verifique os dados: {{deal.numero_alunos}} alunos, plano de interesse: {{deal.plano_interesse}}."

### Automação 3 — Follow-up 3 Dias Após Demo Sem Resposta

**Trigger:** Deal na etapa "Demo Realizada" por 3 dias sem atividade registrada  
**Ação 1:** Criar tarefa para o responsável: "Fazer follow-up pós-demo com {{company.name}}"  
**Ação 2:** Enviar email automatizado (template "Follow-up Pós-Demo"):

> Assunto: "Alguma dúvida sobre o Lexend Scholar, [Nome do Decisor]?"
>
> Olá [Nome do Decisor],
>
> Passaram-se alguns dias desde nossa demo. Queria saber se ficou alguma dúvida ou se posso ajudar com mais alguma informação para a decisão.
>
> Estou disponível para uma conversa rápida de 15 minutos. [Agendar aqui]
>
> Abraços,
> Marlow

---

## 6. Integração MailerLite via Zapier

**Objetivo:** Quando um novo deal é criado no HubSpot, adicionar o contato à lista "HubSpot Prospects" no MailerLite.

### Configuração no Zapier

1. Acesse [zapier.com](https://zapier.com) e crie um novo Zap.

2. **Trigger:** HubSpot → "New Deal"
   - Conta: Lexend Scholar HubSpot
   - Estágio: Qualquer (deixar em branco para todos)

3. **Action:** MailerLite → "Add/Update Subscriber"
   - Email: `{{deal.contact_email}}`
   - Nome: `{{deal.contact_firstname}} {{deal.contact_lastname}}`
   - Campo `nome_escola`: `{{deal.company_name}}`
   - Campo `plano`: `{{deal.plano_interesse}}`
   - Grupo: "HubSpot Prospects" (criar no MailerLite)
   - Tag: `origem-hubspot`

4. Ativar o Zap e testar com um deal existente.

---

## 7. Checklist de Go-Live

- [ ] Conta HubSpot criada
- [ ] Pipeline "Lexend Scholar" configurado com 8 etapas
- [ ] 9 propriedades customizadas criadas
- [ ] 4 views salvas e compartilhadas com o time
- [ ] 3 automações ativas e testadas
- [ ] Integração Zapier com MailerLite ativa
- [ ] Primeiros 10 prospects cadastrados manualmente
- [ ] Reunião de onboarding da equipe de vendas agendada
