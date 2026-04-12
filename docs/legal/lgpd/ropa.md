# ROPA — Registro de Operações de Tratamento de Dados Pessoais

> **Ref:** LS-101 | LGPD Art. 37 | Atualizado: 2026-04-12
> **Empresa:** Lexend Tecnologia Ltda. (Lexend Scholar)
> **Papel:** Operadora de dados (em relação às escolas clientes) e Controladora (em relação a dados de seus próprios usuários/colaboradores)
> **DPO:** [Nome do DPO] — dpo@lexendscholar.com.br
> **Classificação:** Confidencial — disponível à ANPD mediante solicitação

---

## Orientações de Leitura

- **Base Legal** — conforme Art. 7º (dados gerais) e Art. 11 (dados sensíveis) da LGPD
- **Titulares** — pessoas naturais cujos dados são tratados
- **Retenção** — prazo após o qual os dados são excluídos ou anonimizados
- **Medidas de Segurança** — controles técnicos e organizacionais aplicados

---

## Tabela de Atividades de Tratamento

### AT-01 — Cadastro de Usuário (Gestor/Professor/Responsável)

| Campo | Descrição |
|-------|-----------|
| **Finalidade** | Criação de conta de acesso à plataforma Lexend Scholar |
| **Categoria de Dados** | Nome completo, e-mail, telefone, cargo/função, escola vinculada |
| **Base Legal** | Execução de contrato ou procedimentos preliminares (Art. 7º, V) |
| **Titulares** | Gestores escolares, professores, responsáveis por alunos |
| **Compartilhamento** | Supabase (armazenamento), Resend (e-mail de confirmação) |
| **Retenção** | Duração da conta ativa + 5 anos após encerramento |
| **Medidas de Segurança** | Criptografia em trânsito (TLS 1.3), RLS por escola, hash de senha (bcrypt), autenticação de 2 fatores (opcional) |

---

### AT-02 — Autenticação e Controle de Sessão

| Campo | Descrição |
|-------|-----------|
| **Finalidade** | Verificar identidade do usuário e manter sessão segura |
| **Categoria de Dados** | E-mail, hash de senha, JWT, refresh token, IP de acesso, dispositivo |
| **Base Legal** | Execução de contrato (Art. 7º, V); legítimo interesse para segurança (Art. 7º, IX) |
| **Titulares** | Todos os usuários da plataforma |
| **Compartilhamento** | Supabase Auth (processamento interno) |
| **Retenção** | JWT: 1 hora; Refresh token: 7 dias; Logs de IP: 90 dias |
| **Medidas de Segurança** | Tokens armazenados no Keychain (iOS), rotação automática de refresh tokens, bloqueio após tentativas falhas, logs de acesso auditáveis |

---

### AT-03 — Gestão de Alunos

| Campo | Descrição |
|-------|-----------|
| **Finalidade** | Cadastro, organização e gerenciamento de alunos matriculados na escola |
| **Categoria de Dados** | Nome, data de nascimento, CPF (quando aplicável), endereço, foto, contatos dos responsáveis, turma, ano letivo |
| **Base Legal** | Execução de contrato entre Lexend Scholar e escola controladora (Art. 7º, V); para menores: tratamento baseado nas instruções da escola como controladora, com consentimento dos responsáveis |
| **Titulares** | Alunos (potencialmente menores de 18 anos) e seus responsáveis legais |
| **Compartilhamento** | Supabase (armazenamento); acesso restrito à escola controladora via RLS |
| **Retenção** | Enquanto matrícula ativa + 5 anos (prazo legal educacional — LDB) |
| **Medidas de Segurança** | RLS por escola e por perfil de acesso; CPF criptografado com pgcrypto; fotos em Storage com signed-URL (15 min); dados de menores com classificação especial; acesso de suporte Lexend apenas mediante solicitação formal e log |

> **Nota sobre menores (Art. 14 LGPD):** Dados de alunos menores de 18 anos são tratados com proteção reforçada. A escola, como controladora, é responsável por obter consentimento dos responsáveis legais quando necessário.

---

### AT-04 — Registro de Frequência

| Campo | Descrição |
|-------|-----------|
| **Finalidade** | Controle pedagógico e legal de presença/ausência de alunos |
| **Categoria de Dados** | ID do aluno, data, status (presente/ausente/justificado), observações do professor |
| **Base Legal** | Obrigação legal (Art. 7º, II) — LDB exige controle mínimo de 75% de frequência; execução de contrato (Art. 7º, V) |
| **Titulares** | Alunos matriculados |
| **Compartilhamento** | Acesso: professor responsável pela turma, gestor da escola, responsável pelo aluno; não compartilhado externamente |
| **Retenção** | 5 anos (requisito legal educacional) |
| **Medidas de Segurança** | RLS por turma e escola; log de alterações (quem editou, quando); exportação restrita a gestores com log |

---

### AT-05 — Registro de Notas e Avaliações

| Campo | Descrição |
|-------|-----------|
| **Finalidade** | Avaliação pedagógica e acompanhamento do desempenho escolar |
| **Categoria de Dados** | ID do aluno, disciplina, período, nota, tipo de avaliação, observações pedagógicas |
| **Base Legal** | Execução de contrato (Art. 7º, V); obrigação legal para escolas regulamentadas (Art. 7º, II) |
| **Titulares** | Alunos matriculados |
| **Compartilhamento** | Professor, gestor, responsável (somente as notas do próprio filho); nenhum terceiro externo |
| **Retenção** | 5 anos |
| **Medidas de Segurança** | RLS por perfil; boletim gerado como PDF no servidor (não expõe dados via URL pública); log de acesso ao boletim |

---

### AT-06 — Comunicação Interna (Mensagens e Notificações)

| Campo | Descrição |
|-------|-----------|
| **Finalidade** | Facilitar comunicação entre escola, professores e responsáveis de alunos |
| **Categoria de Dados** | Remetente, destinatário, conteúdo da mensagem, timestamp, status de leitura; push token do dispositivo |
| **Base Legal** | Execução de contrato (Art. 7º, V); consentimento para notificações push (Art. 7º, I) |
| **Titulares** | Gestores, professores, responsáveis |
| **Compartilhamento** | Apple APNS (token pseudonimizado para push notifications); Resend (e-mails transacionais); conteúdo de mensagens não compartilhado |
| **Retenção** | Mensagens: 2 anos; Push tokens: até revogação ou desinstalação do app |
| **Medidas de Segurança** | Mensagens em trânsito via TLS; armazenadas no Supabase com RLS; push tokens não vinculados a PII em logs externos |

---

### AT-07 — Gestão Financeira e Assinaturas

| Campo | Descrição |
|-------|-----------|
| **Finalidade** | Cobrança recorrente pelo uso da plataforma Lexend Scholar |
| **Categoria de Dados** | Nome do responsável financeiro, CNPJ/CPF da escola, e-mail de cobrança, histórico de pagamentos, plano contratado; dados de cartão processados exclusivamente pelo Stripe (nunca armazenados no Lexend) |
| **Base Legal** | Execução de contrato (Art. 7º, V); obrigação legal fiscal (Art. 7º, II) |
| **Titulares** | Gestores/representantes legais das escolas clientes |
| **Compartilhamento** | Stripe Inc. (processador de pagamentos, PCI-DSS Level 1); Receita Federal (dados fiscais quando aplicável) |
| **Retenção** | CNPJ/CPF e histórico de pagamentos: 5 anos (obrigação fiscal — Lei 9.430/96); dados de cartão: retidos apenas pelo Stripe |
| **Medidas de Segurança** | Dados de cartão nunca passam pelos servidores Lexend (Stripe.js/SDK); CNPJ criptografado no banco; acesso restrito ao time financeiro; transferência ao Stripe coberta por SCCs |

---

### AT-08 — Logs de Auditoria e Segurança

| Campo | Descrição |
|-------|-----------|
| **Finalidade** | Monitorar acessos, detectar anomalias, responder a incidentes de segurança e requisições de titulares |
| **Categoria de Dados** | User ID, IP de acesso, ação realizada, timestamp, recurso acessado, resultado (sucesso/falha) |
| **Base Legal** | Legítimo interesse (segurança da informação e dos titulares — Art. 7º, IX); obrigação legal (Art. 7º, II) para manter trilha de auditoria |
| **Titulares** | Todos os usuários da plataforma |
| **Compartilhamento** | Não compartilhado; disponível à ANPD mediante requisição legal |
| **Retenção** | 12 meses para logs operacionais; 5 anos para logs relacionados a incidentes |
| **Medidas de Segurança** | Logs imutáveis (append-only); acesso restrito a equipe de segurança; alertas automáticos para comportamentos anômalos (múltiplos logins falhos, exportações em massa) |

---

## Quadro Resumo das Atividades

| # | Atividade | Papel Lexend | Titulares | Base Legal Principal | Dado Mais Sensível | Retenção Máxima |
|---|-----------|-------------|-----------|---------------------|-------------------|----------------|
| AT-01 | Cadastro de usuário | Operadora / Controladora | Gestores, professores, responsáveis | Art. 7º, V | E-mail + telefone | 5 anos pós-encerramento |
| AT-02 | Autenticação | Controladora | Todos os usuários | Art. 7º, V | IP + dispositivo | 90 dias (logs) |
| AT-03 | Gestão de alunos | Operadora | Alunos (menores) | Art. 7º, V + Art. 14 | CPF + dados de saúde | 5 anos pós-matrícula |
| AT-04 | Frequência | Operadora | Alunos | Art. 7º, II + V | Ausências | 5 anos |
| AT-05 | Notas e avaliações | Operadora | Alunos | Art. 7º, V | Desempenho acadêmico | 5 anos |
| AT-06 | Comunicação | Operadora / Controladora | Gestores, professores, responsáveis | Art. 7º, I + V | Conteúdo de mensagens | 2 anos |
| AT-07 | Financeiro | Controladora | Representantes das escolas | Art. 7º, II + V | Dados fiscais | 5 anos (obrigação legal) |
| AT-08 | Logs de auditoria | Controladora | Todos os usuários | Art. 7º, IX | IP + ações | 5 anos (incidentes) |

---

## Revisões do Documento

| Data | Versão | Alteração | Responsável |
|------|--------|-----------|------------|
| 2026-04-12 | 1.0 | Criação inicial | Agente LGPD & Privacy |

---

*Este registro deve ser revisado anualmente ou sempre que houver nova atividade de tratamento. Disponível à ANPD mediante requisição (Art. 37 LGPD). Responsável: DPO.*
