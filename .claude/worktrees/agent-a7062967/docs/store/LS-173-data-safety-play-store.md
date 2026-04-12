# LS-173 — Data Safety Section (Google Play) — Dados de Alunos Menores

## Contexto Legal

O Lexend Scholar processa dados pessoais de **alunos menores de idade**, o que exige
conformidade com:
- **LGPD** (Lei 13.709/2018) — Art. 14 (dados de crianças e adolescentes)
- **Google Play Data Safety** — requisito obrigatório desde julho 2022
- **COPPA** (se houver usuários nos EUA) — aplicável a menores de 13 anos

> Os dados são processados por **instituições de ensino** (controladoras) que contratam
> o Lexend Scholar como operador de dados. Os responsáveis legais pelos alunos deram
> consentimento à escola para coleta desses dados para fins educacionais.

---

## Mapeamento de Dados Coletados

### Categoria: Informações Pessoais

| Tipo de Dado | Coletado | Compartilhado | Finalidade | Obrigatório? |
|-------------|---------|--------------|-----------|-------------|
| Nome do aluno | Sim | Não | Identificação no sistema | Sim |
| Data de nascimento | Sim | Não | Verificação de idade, relatórios | Sim |
| Foto do aluno | Sim (opcional) | Não | Identificação visual | Não |
| CPF do responsável | Sim | Não | Cobrança, nota fiscal | Sim |
| Endereço residencial | Sim | Não | Cadastro legal, correspondência | Sim |
| Telefone do responsável | Sim | Não | Comunicação, notificações | Sim |
| E-mail do responsável | Sim | Não | Notificações, boletim digital | Sim |
| Dados de saúde (alergias, medicamentos) | Sim (opcional) | Não | Emergências médicas na escola | Não |

### Categoria: Dados Financeiros

| Tipo de Dado | Coletado | Compartilhado | Finalidade |
|-------------|---------|--------------|-----------|
| Valor da mensalidade | Sim | Não | Gestão financeira da escola |
| Histórico de pagamentos | Sim | Não | Controle de inadimplência |
| Dados bancários do responsável | Não | — | — |
| Número de cartão de crédito | Não | — | — |

> Pagamentos são processados por gateway externo (Stripe/PagarMe). O Lexend Scholar
> **não armazena** dados de cartão de crédito — apenas confirmação de pagamento.

### Categoria: Dados Acadêmicos

| Tipo de Dado | Coletado | Compartilhado | Finalidade |
|-------------|---------|--------------|-----------|
| Notas e médias | Sim | Não | Boletim, relatórios pedagógicos |
| Frequência (presença/falta) | Sim | Não | Controle de frequência |
| Observações do professor | Sim | Não | Acompanhamento pedagógico |
| Histórico escolar | Sim | Não | Relatórios e transferências |

### Categoria: Dados de Uso do App

| Tipo de Dado | Coletado | Compartilhado | Finalidade |
|-------------|---------|--------------|-----------|
| Logs de acesso (quem fez o quê) | Sim | Não | Auditoria de segurança |
| Sessões de uso (analytics) | Sim (anonimizado) | Não | Melhoria do produto |
| Dados de crash | Sim | Sim (Firebase Crashlytics) | Diagnóstico de bugs |
| Identificador de dispositivo | Sim | Não | Controle de sessão |

### Categoria: Localização

| Tipo de Dado | Coletado | Compartilhado | Finalidade |
|-------------|---------|--------------|-----------|
| Localização precisa | Não | — | — |
| Localização aproximada | Não | — | — |

---

## Preenchimento do Formulário Google Play Data Safety

### Seção 1: Coleta de Dados

**O app coleta ou compartilha dados de usuário com terceiros?**
- [x] Sim, o app coleta dados de usuário

**Todos os dados coletados são criptografados em trânsito?**
- [x] Sim (TLS 1.3)

**Os usuários podem solicitar exclusão de dados?**
- [x] Sim (formulário em lexendscholar.com.br/privacidade/exclusao)

---

### Seção 2: Tipos de Dados — Formulário Play Console

#### Dados Pessoais
- [x] **Nome** — Coletado. Finalidade: Funcionalidade do app. Não compartilhado.
- [x] **Endereço de e-mail** — Coletado. Finalidade: Comunicação, conta do app. Não compartilhado.
- [x] **ID de usuário** — Coletado. Finalidade: Funcionalidade do app. Não compartilhado.
- [x] **Número de telefone** — Coletado. Finalidade: Comunicação. Não compartilhado.
- [x] **Outros dados pessoais** (data de nascimento, endereço) — Coletado. Funcionalidade. Não compartilhado.

#### Dados Financeiros
- [x] **Informações de compra** (histórico de pagamentos) — Coletado. Funcionalidade. Não compartilhado.

#### Informações de Saúde e Fitness
- [x] **Outras informações de saúde** (alergias, restrições médicas) — Coletado (opcional). Funcionalidade. Não compartilhado.

#### Informações e Desempenho do App
- [x] **Logs de crash** — Coletado. Compartilhado com Firebase Crashlytics (Google). Diagnóstico.
- [x] **Dados de diagnóstico** — Coletado. Funcionalidade + diagnóstico. Não compartilhado externamente.

---

### Seção 3: Práticas de Segurança

| Prática | Status | Detalhes |
|---------|--------|---------|
| Dados criptografados em trânsito | Sim | TLS 1.3 em todas as requisições |
| Dados criptografados em repouso | Sim | AES-256 em banco de dados |
| Os usuários podem solicitar exclusão de dados | Sim | Via formulário no website |
| Dados comprometidos com práticas de privacidade independentes | Sim | Política de Privacidade publicada |
| Conformidade com Política de Famílias do Google Play | N/A | App destinado a profissionais adultos |

---

## Conformidade LGPD — Artigo 14 (Dados de Crianças)

### Fundamento Legal para Processamento

O Lexend Scholar processa dados de alunos menores com base no **interesse legítimo da instituição de ensino** (Art. 7, IX) e com **consentimento dos pais/responsáveis** obtido no momento da matrícula pela escola (controladora).

### Medidas Especiais Adotadas

1. **Minimização de dados:** Coletamos apenas dados estritamente necessários para a gestão escolar
2. **Acesso restrito:** Dados de alunos visíveis apenas para funcionários autorizados da escola
3. **Sem publicidade direcionada:** Dados de alunos nunca são usados para fins comerciais
4. **Retenção limitada:** Dados excluídos 5 anos após encerramento do contrato com a escola
5. **Portabilidade:** Escola pode exportar todos os dados em CSV/JSON a qualquer momento
6. **DPO designado:** dpo@lexendscholar.com.br

---

## Política de Privacidade

URL pública: **https://lexendscholar.com.br/privacidade**

Deve conter (requisitos mínimos Play Store):
- [ ] Quais dados são coletados
- [ ] Como os dados são usados
- [ ] Com quem são compartilhados
- [ ] Como solicitar exclusão
- [ ] Dados de contato do DPO
- [ ] Data da última atualização

---

## Checklist de Submissão

- [ ] Formulário Data Safety preenchido no Play Console
- [ ] Política de Privacidade publicada e link validado
- [ ] DPO registrado no Play Console
- [ ] Revisar com advogado especializado em LGPD antes da submissão
- [ ] Testar formulário de exclusão de dados (DSAR)
- [ ] Submeter para revisão interna de conformidade

---

## Referências

- [Google Play Data Safety Help](https://support.google.com/googleplay/android-developer/answer/10787469)
- [LGPD — Art. 14](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
- [Google Play Families Policy](https://support.google.com/googleplay/android-developer/answer/9893335)
