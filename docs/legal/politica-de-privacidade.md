# Política de Privacidade — Lexend Scholar

**Versão:** 1.0
**Data de vigência:** 12 de abril de 2026
**Última atualização:** 12 de abril de 2026

---

## 1. Identificação do Controlador e do Operador

**Controladora dos Dados:** A instituição de ensino contratante do serviço Lexend Scholar ("Escola"), identificada por CNPJ próprio, é a Controladora dos dados pessoais de seus alunos, responsáveis, colaboradores e demais titulares inseridos na Plataforma.

**Operadora dos Dados:** A **Lexend Educação Ltda.**, inscrita no CNPJ sob o nº [●], com sede na cidade de [●], doravante denominada **"Lexend Scholar"**, atua como Operadora de dados conforme a LGPD (Lei nº 13.709/2018), tratando os dados pessoais exclusivamente conforme as instruções da Escola e nos termos desta Política e do Data Processing Agreement (DPA) celebrado entre as partes.

**Encarregado de Dados (DPO):** dpo@lexendscholar.com.br

---

## 2. Âmbito de Aplicação

Esta Política descreve como a Lexend Scholar trata dados pessoais no contexto da operação da plataforma SaaS de gestão escolar **Lexend Scholar**, acessível via aplicativo iOS e interface web, em nome das Escolas contratantes.

---

## 3. Dados Pessoais Coletados

### 3.1. Dados dos Usuários Autorizados da Escola (Diretores, Secretários, Professores)

| Categoria | Exemplos |
|-----------|---------|
| Identificação | Nome completo, e-mail corporativo/pessoal |
| Acesso à plataforma | Login, senha (armazenada em hash bcrypt), perfil de acesso (role) |
| Atividade | Registros de login, ações realizadas na plataforma (logs de auditoria) |

### 3.2. Dados dos Alunos

| Categoria | Exemplos |
|-----------|---------|
| Identificação | Nome completo, data de nascimento, foto (opcional) |
| Documentos | CPF (quando aplicável), RG ou Certidão de Nascimento |
| Acadêmicos | Turma, série, notas, frequência, ocorrências disciplinares, relatórios pedagógicos |
| Matrícula | Número de matrícula, período letivo, situação (ativo, transferido, formado) |

### 3.3. Dados dos Responsáveis Legais

| Categoria | Exemplos |
|-----------|---------|
| Identificação | Nome completo, CPF, RG |
| Contato | E-mail, telefone celular, endereço residencial |
| Vínculo | Grau de parentesco ou relação com o aluno |
| Comunicação | Mensagens enviadas/recebidas via plataforma |

### 3.4. Dados Financeiros

Dados de pagamento das mensalidades da Escola são processados diretamente pelo **Stripe**, nosso processador de pagamentos. A Lexend Scholar não armazena números de cartão de crédito ou dados bancários completos.

### 3.5. Dados Técnicos e de Navegação

- Endereço IP, tipo de dispositivo, sistema operacional, versão do aplicativo
- Cookies analíticos (conforme Cookie Policy), quando consentidos

---

## 4. Finalidades e Bases Legais do Tratamento

| Finalidade | Base Legal (LGPD) |
|------------|------------------|
| Prestação do serviço de gestão escolar contratado | Execução de contrato — Art. 7º, V |
| Comunicação entre escola e responsáveis | Execução de contrato — Art. 7º, V |
| Emissão de relatórios acadêmicos e pedagógicos | Execução de contrato — Art. 7º, V |
| Segurança da plataforma e prevenção de fraudes | Legítimo interesse — Art. 7º, IX |
| Cumprimento de obrigações legais (ex.: registros fiscais) | Cumprimento de obrigação legal — Art. 7º, II |
| Melhoria do produto (dados anonimizados e agregados) | Legítimo interesse — Art. 7º, IX |
| Dados de menores de 13 anos | Consentimento específico do responsável legal — Art. 14, § 1º, LGPD |

---

## 5. Tratamento de Dados de Menores de Idade

### 5.1. Menores em Geral (0–17 anos)

Os alunos cadastrados na Plataforma são, em sua maioria, menores de idade. O tratamento de seus dados pessoais é realizado:

a) **Sempre pela Escola** (Controladora), por meio de seus profissionais autorizados — diretores, secretários e professores — nunca diretamente pelo menor;
b) Com base na execução do contrato de prestação de serviços educacionais entre a Escola e a família do aluno;
c) Com acesso restrito por perfil de usuário e isolamento por `school_id` (Row Level Security no banco de dados).

### 5.2. Crianças Menores de 13 Anos (Art. 14 LGPD)

Para alunos menores de 13 anos, a Escola deve:

a) Obter o consentimento **específico e destacado** de ao menos um dos pais ou responsável legal antes de cadastrar o menor na Plataforma;
b) Garantir que o consentimento seja registrado e possa ser apresentado à Autoridade Nacional de Proteção de Dados (ANPD) ou à Lexend Scholar quando solicitado;
c) Revogar prontamente o acesso ao dado do menor caso o consentimento seja retirado.

A Lexend Scholar não utiliza dados de menores para fins publicitários, de perfilamento comportamental ou qualquer finalidade além da gestão escolar contratada.

---

## 6. Compartilhamento de Dados com Terceiros

A Lexend Scholar não vende, aluga ou cede dados pessoais a terceiros. Os dados são compartilhados **exclusivamente** com os seguintes subprocessadores:

| Subprocessador | Finalidade | País dos Dados | Salvaguardas |
|----------------|-----------|----------------|-------------|
| **Supabase** | Banco de dados e autenticação (Processador de dados) | EUA / UE | Cláusulas contratuais padrão (SCCs) |
| **Stripe** | Processamento de pagamentos (dados financeiros da Escola) | EUA | PCI DSS nível 1; SCCs |

A Lexend Scholar exige de todos os subprocessadores conformidade com a LGPD e/ou normas equivalentes (GDPR), bem como medidas técnicas e organizacionais adequadas de segurança.

---

## 7. Transferência Internacional de Dados

Os dados pessoais tratados na Plataforma podem ser armazenados em servidores localizados nos Estados Unidos da América (infraestrutura Supabase). Essa transferência é realizada mediante cláusulas contratuais padrão aprovadas pela Comissão Europeia (art. 33, II, LGPD) e com adoção de medidas de segurança equivalentes às exigidas pela legislação brasileira.

---

## 8. Retenção e Exclusão dos Dados

| Tipo de Dado | Período de Retenção | Fundamento |
|--------------|---------------------|-----------|
| Dados de alunos (cadastro e acadêmico) | Durante a vigência do contrato + **5 anos** após encerramento | Obrigações legais educacionais e fiscais |
| Dados de responsáveis legais | Durante a vigência do contrato + **5 anos** após encerramento | Obrigações legais |
| Logs de auditoria e acesso | **2 anos** | Segurança e rastreabilidade |
| Dados de pagamento (Stripe) | Conforme política do Stripe (tipicamente 7 anos) | Obrigações fiscais |

Após o período de retenção, os dados são anonimizados ou excluídos de forma segura. A Escola pode solicitar a exclusão antecipada dos dados mediante solicitação fundamentada ao DPO.

---

## 9. Segurança dos Dados

A Lexend Scholar adota as seguintes medidas técnicas e organizacionais:

- **Criptografia em trânsito:** TLS 1.3 em todas as comunicações
- **Criptografia em repouso:** AES-256 no banco de dados Supabase
- **Controle de acesso:** Autenticação multifator (MFA) disponível para todos os usuários; Row Level Security (RLS) por `school_id` isolando dados entre escolas
- **Senhas:** Armazenadas em hash bcrypt com salt
- **Monitoramento:** Logs de auditoria imutáveis para todas as ações sensíveis
- **Backups:** Automáticos com frequência diária, retidos por 30 dias
- **Notificação de incidentes:** Em até 72 horas após ciência de violação de dados

---

## 10. Direitos dos Titulares (Art. 18 LGPD)

Os titulares de dados pessoais (alunos maiores, responsáveis legais e usuários autorizados) têm os seguintes direitos, exercíveis mediante solicitação ao DPO:

| Direito | Descrição |
|---------|-----------|
| **Confirmação e Acesso** | Confirmar a existência do tratamento e obter cópia dos dados |
| **Correção** | Solicitar a correção de dados incompletos, inexatos ou desatualizados |
| **Anonimização, Bloqueio ou Eliminação** | Solicitar a anonimização ou exclusão de dados desnecessários ou excessivos |
| **Portabilidade** | Receber os dados em formato estruturado e interoperável |
| **Eliminação** | Solicitar a exclusão dos dados tratados com base em consentimento |
| **Informação** | Obter informação sobre com quais entidades os dados são compartilhados |
| **Revogação do consentimento** | Revogar consentimento previamente dado, sem prejuízo da legalidade do tratamento anterior |
| **Oposição** | Opor-se ao tratamento baseado em legítimo interesse, em caso de descumprimento da LGPD |
| **Revisão de decisões automatizadas** | Solicitar revisão de decisões tomadas exclusivamente por meios automatizados |

**Como exercer:** Os titulares devem, preferencialmente, contatar a Escola (Controladora). Caso o pedido envolva atribuições da Lexend Scholar como Operadora, a solicitação pode ser enviada para: **dpo@lexendscholar.com.br**. O prazo de resposta é de **15 dias úteis**, prorrogável por igual período mediante justificativa.

---

## 11. Cookies e Tecnologias de Rastreamento

O uso de cookies é regido pela **Cookie Policy** disponível em `/docs/legal/cookie-policy.md`. O website da Lexend Scholar utiliza exclusivamente cookies analíticos de primeira parte (Plausible Analytics, sem coleta de dados pessoais identificáveis), condicionados ao consentimento do usuário.

A Plataforma SaaS em si utiliza apenas cookies de sessão estritamente necessários ao funcionamento do serviço.

---

## 12. Alterações nesta Política

A Lexend Scholar poderá atualizar esta Política periodicamente. Alterações materiais serão comunicadas às Escolas com antecedência mínima de **30 dias** por e-mail e aviso na Plataforma. O uso continuado da Plataforma após esse prazo implica aceitação das alterações.

---

## 13. Contato e Encarregado de Dados (DPO)

Para questões relacionadas a esta Política, exercício de direitos dos titulares, solicitações de auditoria ou notificação de incidentes:

**Encarregado de Dados (DPO):** dpo@lexendscholar.com.br
**Legal:** legal@lexendscholar.com.br
**Endereço:** [●], São Paulo/SP, Brasil

Para reclamações não resolvidas, os titulares podem contatar a **Autoridade Nacional de Proteção de Dados (ANPD)**: www.gov.br/anpd

---

*Lexend Educação Ltda. (Lexend Scholar) — Todos os direitos reservados.*
