# Data Safety Section — Google Play Console

> Issue: LS-173 | Preencher Data Safety section (dados de alunos menores)

---

## Dados Coletados e Finalidade

| Dado | Finalidade | Compartilhado com Terceiros? | Obrigatório? |
|------|-----------|------------------------------|-------------|
| Nome e email do usuário (diretor/professor/secretário) | Autenticação e comunicação com o usuário | Não | Sim |
| Nome e matrícula de alunos | Prestação do serviço educacional contratado | Não | Sim |
| Dados de frequência e notas | Funcionalidade principal do app | Não | Sim |
| Dados financeiros da escola (valores, cobranças) | Gestão financeira e billing via Stripe | Stripe (processador de pagamento) | Sim |
| Fotos de perfil (opcional) | Identificação visual no app | Não | Não |
| Dados de uso do app (analytics) | Melhoria do produto | Firebase Analytics (agregado, sem PII) | Não |
| Tokens de push notification | Envio de comunicados e alertas | Não | Não |
| Logs de acesso | Segurança e auditoria | Não | Sim |

---

## Práticas de Segurança

| Prática | Implementação |
|---------|--------------|
| Dados em trânsito | Criptografados com TLS 1.3 |
| Dados em repouso | Criptografados com AES-256 (Supabase/PostgreSQL) |
| Venda de dados | Nunca — dados não são vendidos a terceiros |
| Acesso interno | Role-based access control (RBAC) — mínimo necessário |
| Auditoria | Logs de acesso retidos por 90 dias |
| Exclusão de dados | Dados deletados em 30 dias após cancelamento da conta |

---

## Dados de Menores de 18 Anos

### Base Legal (LGPD — Lei 13.709/2018)

O Lexend Scholar processa dados de alunos, que podem ser menores de 18 anos, com base no **Art. 7º, V (execução de contrato)** e **Art. 14** da LGPD:

- **Controladora dos dados:** A escola (pessoa jurídica contratante do Lexend Scholar)
- **Operadora dos dados:** Lexend Scholar Tecnologia Ltda.
- **Base legal:** Contrato entre a escola e o responsável/aluno para prestação de serviços educacionais
- **Lexend Scholar como operadora** não processa dados de menores diretamente, mas sob instrução da escola (controladora)

### Conformidade LGPD Art. 14 (Dados de Crianças e Adolescentes)

- O Lexend Scholar não coleta dados de menores diretamente — a escola é a intermediária e controladora
- Os dados de alunos são inseridos por professores e secretários autorizados pela escola
- Nenhum dado de aluno é utilizado para fins de marketing, publicidade ou compartilhado com terceiros além dos processadores técnicos listados
- A escola é responsável por obter os consentimentos necessários dos responsáveis legais dos alunos

---

## Processadores de Dados (Sub-operadores)

| Processador | Finalidade | Localização dos Dados | Link de Privacidade |
|-------------|-----------|----------------------|---------------------|
| Supabase | Banco de dados e autenticação | EUA (com opção de Brasil) | supabase.com/privacy |
| Stripe | Processamento de pagamentos | EUA | stripe.com/privacy |
| Firebase | Push notifications e analytics | EUA | firebase.google.com/policies/privacy |
| Apple APNs | Push notifications iOS | EUA | apple.com/legal/privacy |
| Google FCM | Push notifications Android | EUA | policies.google.com/privacy |

---

## Solicitações de Usuários

### Exclusão de Dados
- **Como solicitar:** email para suporte@lexendscholar.com.br com assunto "Solicitação de Exclusão de Dados"
- **Prazo:** dados deletados em até **30 dias** após o cancelamento ou solicitação
- **Escopo:** todos os dados do usuário e da escola associada

### Acesso aos Dados
- **Como solicitar:** email para dpo@lexendscholar.com.br
- **Prazo:** resposta em até **15 dias úteis** (conforme LGPD Art. 18)
- **Formato:** JSON ou CSV

### Portabilidade de Dados
- Disponível via exportação no próprio app (alunos → exportar CSV, boletins → exportar PDF)
- Para exportação completa: suporte@lexendscholar.com.br

---

## Contatos

| Função | Email |
|--------|-------|
| DPO (Encarregado de Proteção de Dados) | dpo@lexendscholar.com.br |
| Suporte técnico e exclusão de dados | suporte@lexendscholar.com.br |
| Jurídico / conformidade | juridico@lexendscholar.com.br |

---

## Preenchimento no Google Play Console

### Seção "Data Safety" — Respostas

1. **Você coleta ou compartilha dados do usuário com terceiros?** → Sim
2. **Todos os dados são criptografados em trânsito?** → Sim (TLS 1.3)
3. **Os usuários podem solicitar exclusão de dados?** → Sim
4. **O app segue a Política de Família do Google Play (dados de crianças)?** → Sim (dados processados sob instrução da escola controladora)

### Tipos de Dados a Declarar no Console

- [x] **Informações pessoais:** nome, email (usuário adulto/professor)
- [x] **Informações financeiras:** histórico de compras, pagamentos
- [x] **Informações de saúde e aptidão:** não aplicável
- [x] **Mensagens:** comunicados enviados no app
- [x] **Fotos e vídeos:** fotos de perfil (opcional, não obrigatório)
- [x] **Identificadores:** ID do dispositivo para push notifications
- [x] **Dados de uso do app:** interações, diagnósticos
