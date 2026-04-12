# Modelo de Pricing — Lexend Scholar

## Tabela de Planos

| Plano | Alunos | Mensal | Anual | Economia |
|-------|--------|--------|-------|---------|
| Starter | até 100 | R$ 297 | R$ 2.970 | 2 meses grátis |
| Pro | até 500 | R$ 697 | R$ 6.970 | 2 meses grátis |
| Enterprise | Ilimitado | R$ 1.497 | R$ 14.970 | 2 meses grátis |

> Todos os planos incluem **14 dias de trial gratuito** sem necessidade de cartão de crédito.

---

## Funcionalidades por Plano

### Starter — até 100 alunos

Módulos básicos para gestão escolar essencial:

- Controle de frequência (registro por turma e aluno)
- Lançamento de notas e boletim escolar
- Gestão financeira: mensalidades, inadimplência e recibos
- Cadastro de alunos, turmas e responsáveis
- Dashboard com indicadores resumidos
- Suporte via email (resposta em até 48h)
- Exportação de dados em XLSX

### Pro — até 500 alunos

Tudo do Starter, mais:

- Relatórios avançados (frequência, desempenho, financeiro por período)
- App Android para professores e responsáveis
- Operação multi-turno (manhã, tarde, noite)
- Notificações push para responsáveis (presença, notas, pagamentos)
- Widgets de resumo na tela inicial do Android
- Suporte via WhatsApp e email (resposta em até 24h)

### Enterprise — alunos ilimitados

Tudo do Pro, mais:

- API REST completa para integrações
- White-label (logo e cores da escola)
- SLA 99,9% de disponibilidade
- Onboarding dedicado com consultor
- Importação em massa de dados (planilha Excel/CSV)
- Suporte prioritário 24/7 via WhatsApp, email e chat
- Treinamento da equipe incluído

---

## Justificativa de Pricing

### Custo por aluno — perspectiva do cliente

| Plano | Custo por aluno/mês |
|-------|-------------------|
| Starter (100 alunos) | R$ 2,97 |
| Pro (500 alunos) | R$ 1,39 |
| Enterprise (1.000 alunos) | < R$ 1,50 |

**Referência de mercado**: uma caneta BIC custa em média R$ 3,00. O Lexend Scholar Starter custa **menos do que uma caneta por mês por aluno**.

### Comparativo com sistemas legados no Brasil

| Solução | Custo médio/mês | App Mobile | API | Trial |
|---------|----------------|------------|-----|-------|
| Sistemas legados médios | R$ 500 – R$ 2.000 | Não incluso | Raramente | Não |
| Planilhas Google/Excel | Gratuito | Não | Não | — |
| **Lexend Scholar Starter** | **R$ 297** | **Incluso no Pro+** | **Incluso no Enterprise** | **14 dias grátis** |
| **Lexend Scholar Pro** | **R$ 697** | **Incluso** | **Incluso no Enterprise** | **14 dias grátis** |

### Por que o desconto anual de 2 meses?

O pagamento anual antecipado:
- Reduz churn involuntário (cartão expirado, esquecimento)
- Melhora previsibilidade de receita (MRR → ARR)
- Incentivo de **~16,7% de desconto** sem parecer agressivo

---

## Price IDs Stripe (configurar via variáveis de ambiente)

```env
STARTER_PRICE_ID=price_...
PRO_PRICE_ID=price_...
ENTERPRISE_PRICE_ID=price_...
```

Os Price IDs devem ser criados no Stripe Dashboard para os produtos:
- `lexend_starter_monthly` / `lexend_starter_yearly`
- `lexend_pro_monthly` / `lexend_pro_yearly`
- `lexend_enterprise_monthly` / `lexend_enterprise_yearly`

---

## Histórico de Revisões

| Data | Versão | Alteração |
|------|--------|-----------|
| 2024-01 | 1.0 | Lançamento dos 3 planos iniciais |
| 2025-01 | 1.1 | Adição do app Android ao plano Pro |
| 2026-04 | 1.2 | Inclusão de widgets Glance e notificações FCM no Pro |
