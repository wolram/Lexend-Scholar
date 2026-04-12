# ACORDO DE PROCESSAMENTO DE DADOS (DPA)
## Data Processing Agreement — Lexend Scholar

> **Ref:** LS-102 | LGPD Arts. 7º, 37, 39, 46 | Versão: 1.0 | Data: 2026-04-12
> **Classificação:** Template — preencher com dados da escola contratante

---

## PARTES

**OPERADORA:**
Lexend Tecnologia Ltda.
CNPJ: [CNPJ da Lexend]
Endereço: [Endereço da Lexend]
E-mail de contato de privacidade: privacidade@lexendscholar.com.br
("**Lexend**" ou "**Operadora**")

**CONTROLADORA:**
[Razão Social da Escola]
CNPJ: [CNPJ da Escola]
Endereço: [Endereço da Escola]
E-mail de contato: [E-mail do responsável legal]
("**Escola**" ou "**Controladora**")

Doravante individualmente denominadas "Parte" e, conjuntamente, "Partes".

---

## CLÁUSULA 1 — OBJETO E DEFINIÇÕES

**1.1** O presente Acordo de Processamento de Dados ("DPA" ou "Acordo") regula o tratamento de dados pessoais pela Operadora em nome da Controladora, no âmbito da prestação dos serviços de gestão escolar disponibilizados pela plataforma **Lexend Scholar** ("Serviço"), conforme contrato principal firmado entre as Partes ("Contrato de Serviço").

**1.2** Para os fins deste Acordo, aplicam-se as definições da Lei nº 13.709/2018 (LGPD), em especial:
- **Dado Pessoal:** informação relacionada a pessoa natural identificada ou identificável;
- **Dado Pessoal Sensível:** dado sobre origem racial/étnica, convicção religiosa, opinião política, saúde, vida sexual, dado genético ou biométrico;
- **Tratamento:** toda operação realizada com dados pessoais (coleta, armazenamento, uso, compartilhamento, eliminação etc.);
- **Controladora:** pessoa que decide sobre o tratamento (a Escola);
- **Operadora:** pessoa que realiza o tratamento em nome da Controladora (a Lexend);
- **Titular:** pessoa natural a quem os dados pertencem (alunos, responsáveis, professores).

**1.3** Este DPA prevalece sobre qualquer disposição contrária no Contrato de Serviço no que diz respeito ao tratamento de dados pessoais.

---

## CLÁUSULA 2 — PAPÉIS E RESPONSABILIDADES

**2.1 A Escola é a Controladora.** A Escola determina as finalidades e os meios do tratamento dos dados pessoais de seus alunos, professores e responsáveis cadastrados na plataforma.

**2.2 A Lexend é a Operadora.** A Lexend realiza o tratamento dos dados pessoais exclusivamente conforme as instruções documentadas da Escola e nos limites necessários para a prestação do Serviço.

**2.3** A Operadora não utilizará os dados pessoais recebidos para finalidades próprias, exceto:
(a) quando necessário para prestação do Serviço contratado;
(b) quando exigido por lei ou ordem judicial.

**2.4** Cada Parte é responsável pelo cumprimento das obrigações que lhe cabem sob a LGPD em seu respectivo papel.

---

## CLÁUSULA 3 — INSTRUÇÕES DE TRATAMENTO

**3.1** A Operadora tratará os dados pessoais somente conforme as instruções documentadas da Controladora, que incluem:

| Operação autorizada | Descrição |
|---------------------|-----------|
| Coleta | Cadastro de alunos, turmas, professores e responsáveis inseridos pela Escola |
| Armazenamento | Armazenamento seguro na infraestrutura Supabase (AWS São Paulo) |
| Organização e estruturação | Agrupamento por turma, ano letivo, disciplina |
| Uso para prestação do Serviço | Geração de boletins, relatórios de frequência, notificações |
| Comunicação interna | Mensagens entre escola e responsáveis via plataforma |
| Exportação | Geração de relatórios CSV/PDF a pedido da Escola |
| Eliminação | Exclusão de dados conforme solicitação da Escola ou ao término do contrato |

**3.2** A Operadora notificará imediatamente a Controladora caso considere que uma instrução recebida viola a LGPD ou outra norma aplicável.

**3.3** A Controladora é a única responsável pela obtenção dos consentimentos necessários para o tratamento de dados de alunos menores de 18 anos, conforme Art. 14 da LGPD.

---

## CLÁUSULA 4 — SUB-OPERADORES AUTORIZADOS

**4.1** A Controladora autoriza a Operadora a contratar os seguintes sub-operadores para auxiliar na prestação do Serviço:

| Sub-operador | País/Região | Serviço prestado | Dados compartilhados | Garantia |
|---|---|---|---|---|
| **Supabase Inc.** | Brasil — AWS São Paulo (sa-east-1) | Banco de dados, autenticação, armazenamento de arquivos | Todos os dados cadastrados na plataforma | Supabase DPA + AWS BAA |
| **Stripe Inc.** | EUA | Processamento de pagamentos | Nome, e-mail, CNPJ/CPF (dados financeiros da escola) | SCCs; PCI-DSS Level 1 |
| **Resend Inc.** | EUA | Envio de e-mails transacionais | Nome e e-mail do destinatário | SCCs |
| **Apple Inc. (APNS)** | EUA | Push notifications | Push token (pseudonimizado) | SCCs |

**4.2** A Operadora manterá esta lista atualizada e notificará a Controladora com **30 dias de antecedência** em caso de inclusão ou substituição de sub-operadores. A Controladora poderá objetar a mudança nesse prazo; caso não haja objeção, considera-se aprovada.

**4.3** A Operadora exigirá que cada sub-operador mantenha nível equivalente de proteção ao estabelecido neste DPA.

---

## CLÁUSULA 5 — MEDIDAS TÉCNICAS E ORGANIZACIONAIS DE SEGURANÇA

**5.1** A Operadora implementa e mantém as seguintes medidas:

### Medidas Técnicas

| Medida | Descrição |
|--------|-----------|
| Criptografia em trânsito | TLS 1.3 em todas as comunicações entre app e servidor |
| Criptografia em repouso | AES-256 nos servidores Supabase/AWS |
| Criptografia de campos sensíveis | CPF, laudos médicos criptografados com pgcrypto no banco de dados |
| Controle de acesso (RLS) | Row Level Security no banco de dados — cada usuário acessa apenas dados autorizados |
| Autenticação forte | Senha + suporte a 2FA; tokens JWT de curta duração (1h) |
| Backups | Backups automáticos diários com retenção de 30 dias; backups mensais por 1 ano |
| Monitoramento | Alertas de segurança em tempo real para acessos anômalos |
| Segregação de ambientes | Produção, staging e desenvolvimento completamente separados |
| Logs de auditoria | Registro imutável de acessos e operações sensíveis |

### Medidas Organizacionais

| Medida | Descrição |
|--------|-----------|
| Política de privacidade interna | Colaboradores treinados em LGPD antes do acesso a dados pessoais |
| Acesso mínimo (least privilege) | Colaboradores têm acesso apenas aos dados necessários para sua função |
| Acordos de confidencialidade | Todos os colaboradores e prestadores assinam NDA + cláusula de privacidade |
| DPO designado | Encarregado de proteção de dados nomeado (contato: dpo@lexendscholar.com.br) |
| Avaliações de segurança | Testes de penetração anuais; revisão de vulnerabilidades semestral |
| Plano de resposta a incidentes | Procedimento documentado (ver Cláusula 6) |

---

## CLÁUSULA 6 — NOTIFICAÇÃO E RESPOSTA A INCIDENTES DE SEGURANÇA

**6.1** Em caso de incidente de segurança que resulte em, ou que possa resultar em, acesso não autorizado, perda, destruição ou divulgação de dados pessoais, a Operadora:

**(a) Dentro de 24 horas** após a confirmação do incidente:
- Notificará a Controladora por e-mail (contato registrado no Contrato de Serviço) com informações preliminares disponíveis.

**(b) Dentro de 48 horas:**
- Fornecerá relatório detalhado contendo: natureza do incidente, dados afetados, número estimado de titulares, medidas adotadas para conter o incidente, e medidas preventivas para evitar recorrência.

**(c) Dentro de 72 horas** (conforme Art. 48 LGPD):
- Auxiliará a Controladora na notificação à **Autoridade Nacional de Proteção de Dados (ANPD)** e, quando necessário, aos titulares afetados.

**6.2** A Controladora é responsável pela decisão de notificar a ANPD e os titulares, com base nas informações fornecidas pela Operadora.

**6.3** A Operadora cooperará plenamente com a Controladora durante a investigação do incidente, fornecendo logs, evidências e suporte técnico necessários.

**6.4 Contato de emergência para incidentes:** seguranca@lexendscholar.com.br | WhatsApp: +55 [número]

---

## CLÁUSULA 7 — DIREITOS DOS TITULARES

**7.1** Quando um titular de dados (aluno, responsável, professor) exercer seus direitos previstos na LGPD junto à Escola (controladora), a Escola poderá solicitar à Lexend (operadora) que:

| Direito (Art. 18 LGPD) | Ação da Operadora | Prazo |
|---|---|---|
| Confirmação de existência de tratamento | Confirmar quais dados existem na plataforma | 5 dias úteis |
| Acesso aos dados | Exportar dados do titular em formato legível (JSON/CSV) | 10 dias úteis |
| Correção de dados | Corrigir dado incorreto mediante instrução da Escola | 5 dias úteis |
| Anonimização, bloqueio ou eliminação | Anonimizar ou excluir dados conforme instrução | 10 dias úteis |
| Portabilidade | Exportar dados em formato interoperável (JSON) | 15 dias úteis |
| Eliminação após revogação de consentimento | Excluir dados quando base legal era consentimento | 10 dias úteis |
| Informação sobre compartilhamento | Listar sub-operadores e dados compartilhados | 5 dias úteis |
| Revogação de consentimento | Encerrar tratamento baseado em consentimento | Imediato |

**7.2** Solicitações de titulares direto à Lexend (operadora) serão redirecionadas à Escola (controladora) responsável, a menos que a Escola autorize a Lexend a responder diretamente.

**7.3** A Lexend disponibilizará o canal privacidade@lexendscholar.com.br para recebimento de solicitações. Ver Processo DSAR completo em `docs/legal/lgpd/dsar-process.md`.

---

## CLÁUSULA 8 — TRANSFERÊNCIA INTERNACIONAL

**8.1** A Operadora armazenará todos os dados pessoais de alunos e dados pedagógicos em servidores localizados no Brasil (AWS São Paulo — sa-east-1).

**8.2** Dados financeiros processados pelo Stripe poderão ser transferidos aos EUA, com cobertura de Standard Contractual Clauses (SCCs) aprovadas pela Comissão Europeia e aplicadas por analogia às exigências da LGPD.

**8.3** A Operadora notificará a Controladora antes de realizar qualquer nova transferência internacional não prevista neste Acordo.

---

## CLÁUSULA 9 — AUDITORIA E TRANSPARÊNCIA

**9.1** A Operadora fornecerá à Controladora, mediante solicitação formal com prazo de **15 dias úteis**:
- Relatório de conformidade LGPD;
- Evidências das medidas de segurança implementadas;
- Logs de acesso relacionados à escola da Controladora.

**9.2** A Controladora poderá realizar ou contratar auditorias de segurança de dados com aviso prévio de **30 dias**, desde que não perturbem as operações normais.

**9.3** A Operadora notificará a Controladora sobre qualquer solicitação de autoridade pública de acesso aos dados da Controladora, salvo quando proibida por lei.

---

## CLÁUSULA 10 — PRAZO, ENCERRAMENTO E DEVOLUÇÃO DE DADOS

**10.1** Este DPA vigora pelo mesmo prazo do Contrato de Serviço.

**10.2** Ao término do Contrato de Serviço, a Operadora:

(a) Disponibilizará, por **30 dias**, exportação completa dos dados da Escola em formato JSON/CSV para download;

(b) Após o prazo de 30 dias, realizará a **exclusão segura** de todos os dados pessoais da Escola dos sistemas de produção;

(c) Manterá apenas dados exigidos por obrigação legal (dados fiscais por 5 anos conforme legislação tributária);

(d) Emitirá **certificado de exclusão** dentro de 60 dias após o término do contrato.

**10.3** A Escola poderá solicitar exclusão antecipada mediante notificação formal, respeitado o prazo de 30 dias para processamento.

---

## CLÁUSULA 11 — DISPOSIÇÕES GERAIS

**11.1** As Partes comprometem-se a tratar as informações deste Acordo com confidencialidade, nos termos do NDA firmado.

**11.2** Qualquer alteração a este DPA deve ser feita por escrito e assinada por ambas as Partes.

**11.3** Este DPA é regido pelas leis da República Federativa do Brasil. As Partes elegem o foro da Comarca de [Cidade], Estado de [Estado], para dirimir controvérsias.

**11.4** Se qualquer disposição deste DPA for considerada inválida, as demais permanecerão em pleno vigor.

---

## ASSINATURAS

**CONTROLADORA — [Nome da Escola]**

```
Nome:    _________________________________
Cargo:   _________________________________
CPF:     _________________________________
Data:    _________________________________
Assinatura: ______________________________
```

**OPERADORA — Lexend Tecnologia Ltda.**

```
Nome:    _________________________________
Cargo:   _________________________________
CPF:     _________________________________
Data:    _________________________________
Assinatura: ______________________________
```

---

*Template revisado por [Nome do Advogado], OAB/[Estado] nº [Número]. Versão 1.0 — 2026-04-12.*
*Próxima revisão programada: 2027-04-12 ou após alteração legislativa relevante.*
