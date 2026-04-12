# Processo de Atendimento a Titulares (DSAR)
## Data Subject Access Request — Lexend Scholar

> **Ref:** LS-103 | LGPD Arts. 17–22 | Versão: 1.0 | Atualizado: 2026-04-12
> **Responsável:** DPO — privacidade@lexendscholar.com.br

---

## 1. O que é um DSAR?

Um **DSAR (Data Subject Access Request)**, ou Solicitação de Acesso do Titular de Dados, é o exercício formal dos direitos garantidos pelo Art. 18 da LGPD por parte de qualquer pessoa natural cujos dados pessoais são tratados pelo Lexend Scholar.

No contexto do Lexend Scholar, titulares podem ser:
- **Alunos** (ou seus responsáveis legais, quando menores de 18 anos)
- **Professores** cadastrados na plataforma
- **Gestores escolares** e outros usuários
- **Responsáveis por alunos** (guardiões)

### Por que é importante?

A LGPD garante que qualquer pessoa possa saber quais dados seus são tratados, por quem, com qual finalidade, e pode exigir correção, exclusão ou portabilidade. O descumprimento pode resultar em sanções da ANPD (multas de até R$ 50 milhões ou 2% do faturamento).

---

## 2. Canais de Recebimento

### Canal Principal
**E-mail:** privacidade@lexendscholar.com.br
- Monitorado em dias úteis, horário comercial (9h–18h, horário de Brasília)
- Resposta de confirmação de recebimento automática em até 2 horas

### Canal Alternativo (quando disponível)
**Formulário Web:** https://lexendscholar.com.br/privacidade/solicitar
- Disponível 24/7
- Formulário estruturado que coleta automaticamente os dados necessários para verificação de identidade

### Para Escolas (via Controladora)
Escolas podem encaminhar solicitações de seus alunos e responsáveis diretamente ao DPO da Lexend, conforme previsto no DPA (Cláusula 7).

---

## 3. Prazo Legal

| Marco | Prazo | Base Legal |
|-------|-------|-----------|
| Confirmação de recebimento | Imediato (automático) | Boa prática |
| **Resposta à solicitação** | **15 dias corridos** | **Art. 19, LGPD** |
| Prorrogação justificada | +15 dias (comunicar ao titular) | Art. 19, §3º, LGPD |
| Notificação à ANPD em caso de negativa | Na mesma resposta ao titular | Art. 19, §4º, LGPD |

**Importante:** O prazo de 15 dias começa a contar a partir da **confirmação da identidade do titular**, não do recebimento inicial.

---

## 4. Tipos de Solicitação e Ações Correspondentes

### 4.1 Confirmação de Existência e Acesso (Art. 18, I e II)

O titular quer saber **se** seus dados são tratados e **quais** são.

**Ação:**
- Gerar relatório completo dos dados do titular na plataforma
- Incluir: categorias de dados, finalidades, com quem são compartilhados, prazo de retenção
- Formato: PDF ou JSON estruturado

### 4.2 Correção de Dados (Art. 18, III)

O titular quer **corrigir** um dado incorreto, desatualizado ou incompleto.

**Ação:**
- Verificar o dado incorreto apontado
- Se a correção for de dado gerenciado pela escola (aluno): notificar a escola controladora para que realize a correção
- Se a correção for de dado de conta do próprio usuário: realizar a correção diretamente

### 4.3 Anonimização, Bloqueio ou Eliminação (Art. 18, IV)

O titular quer que dados **desnecessários, excessivos ou tratados em desconformidade** sejam eliminados.

**Ação:**
- Verificar se há base legal que justifique a manutenção (ex.: obrigação legal, prazo de retenção)
- Se não houver: realizar eliminação ou anonimização
- Se houver: explicar ao titular a base legal e o prazo
- Emitir certificado de eliminação quando aplicável

### 4.4 Portabilidade (Art. 18, V)

O titular quer **exportar seus dados** para outro serviço.

**Ação:**
- Gerar exportação completa dos dados do titular em formato interoperável (JSON ou CSV)
- Incluir: dados cadastrais, histórico de uso, configurações relevantes
- Dados pedagógicos (notas, frequência): exportar mediante confirmação da escola controladora

### 4.5 Informação sobre Compartilhamento (Art. 18, VI)

O titular quer saber **com quem** seus dados são compartilhados.

**Ação:**
- Fornecer lista de sub-operadores (conforme DPA Cláusula 4)
- Especificar quais dados de cada categoria são compartilhados e por quê

### 4.6 Revogação de Consentimento (Art. 18, IX)

O titular quer **retirar o consentimento** dado anteriormente.

**Ação:**
- Confirmar quais tratamentos têm base em consentimento
- Encerrar esses tratamentos imediatamente após confirmação
- Comunicar consequências práticas (ex.: perda de acesso a funcionalidades que dependem do consentimento)
- Dados cuja base legal não é consentimento continuam sendo tratados

### 4.7 Eliminação completa / Exclusão de conta (Art. 18, VI)

O titular quer **excluir completamente** sua conta e todos os dados.

**Ação:**
- Verificar vínculos com escola (dados de aluno gerenciados pela escola precisam de autorização da escola controladora)
- Realizar hard delete dos dados de conta do usuário
- Anonimizar dados que precisam ser mantidos por obrigação legal
- Emitir certificado de exclusão em até 30 dias

---

## 5. Fluxo Interno de Atendimento

```
┌─────────────────────────────────────────────────────────────────┐
│                    RECEBIMENTO DA SOLICITAÇÃO                    │
│           privacidade@lexendscholar.com.br / formulário web      │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              PASSO 1: REGISTRO (Dia 0)                          │
│  • Registrar no sistema de tickets (ID único)                   │
│  • Enviar e-mail de confirmação ao titular                      │
│  • Classificar tipo de solicitação                              │
│  • Atribuir ao DPO ou responsável designado                     │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│           PASSO 2: VERIFICAÇÃO DE IDENTIDADE (Dias 1–3)         │
│  • Solicitar documento de identidade (RG, CPF, CNH)             │
│  • Para menores: documento do responsável legal                 │
│  • Para procuradores: procuração + documento                    │
│  • Verificar se o titular tem vínculo com a plataforma          │
│  • Confirmar por e-mail quando identidade validada              │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              PASSO 3: PROCESSAMENTO (Dias 3–12)                 │
│  • Executar ação correspondente ao tipo de solicitação          │
│  • Se envolver escola controladora: notificar escola            │
│  • Documentar todas as ações realizadas                         │
│  • Preparar resposta completa para o titular                    │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                PASSO 4: RESPOSTA (até Dia 15)                   │
│  • Enviar resposta formal ao titular                            │
│  • Incluir todas as informações solicitadas                     │
│  • Informar recursos disponíveis (ANPD) se houver negativa      │
│  • Registrar conclusão no sistema de tickets                    │
│  • Arquivar documentação por 5 anos                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Verificação de Identidade

Para proteger os dados dos titulares, é obrigatório verificar a identidade antes de processar qualquer solicitação.

| Situação | Documentação exigida |
|----------|---------------------|
| Titular adulto | Selfie com documento de identidade (RG, CNH ou Passaporte) |
| Titular menor de 18 anos | Responsável legal: documento de identidade + comprovante de guarda |
| Procurador | Procuração pública/particular + documento do procurador + do titular |
| Representante legal da escola | Contrato social ou procuração empresarial |

**Prazo para envio de documentos:** 10 dias corridos após solicitação. Se não houver resposta, a solicitação é arquivada com comunicação ao titular.

---

## 7. Situações Especiais

### 7.1 Solicitação Manifestamente Infundada ou Excessiva
- Documentar a análise
- Comunicar ao titular a negativa com justificativa fundamentada
- Informar direito de reclamação à ANPD

### 7.2 Solicitação de Dados Gerenciados pela Escola
- Notificar a escola (controladora) da solicitação
- A escola tem 10 dias para responder à Lexend
- Lexend coordena a resposta ao titular com base nas instruções da escola

### 7.3 Titular Falecido
- Herdar direitos: cônjuge, ascendentes ou descendentes diretos
- Exigir certidão de óbito + documento comprobatório do vínculo

### 7.4 Dados que NÃO podem ser eliminados
Informar ao titular e documentar quando dados não podem ser eliminados por:
- Obrigação legal ou regulatória (ex.: dados fiscais por 5 anos)
- Defesa de direito em processo judicial
- Cumprimento de obrigação com o poder público

---

## 8. Templates de Resposta

### 8.1 Confirmação de Recebimento (Automática)

```
Assunto: [Lexend Scholar] Recebemos sua solicitação de privacidade — #[ID]

Olá, [Nome],

Confirmamos o recebimento de sua solicitação de [tipo] referente aos
seus dados pessoais no Lexend Scholar.

Número de protocolo: #[ID]
Data de recebimento: [Data]
Prazo de resposta: até [Data + 15 dias]

O próximo passo é a verificação da sua identidade. Em breve entraremos
em contato com as instruções necessárias.

Qualquer dúvida, responda a este e-mail.

Atenciosamente,
Equipe de Privacidade — Lexend Scholar
privacidade@lexendscholar.com.br
```

### 8.2 Solicitação de Verificação de Identidade

```
Assunto: [Lexend Scholar] Protocolo #[ID] — Verificação de identidade necessária

Olá, [Nome],

Para processar sua solicitação de [tipo] com segurança, precisamos
verificar sua identidade.

Por favor, envie em resposta a este e-mail, em até 10 dias corridos:
• Uma selfie segurando seu documento de identidade aberto (RG, CNH ou Passaporte)
• O documento deve estar legível na foto

Após a verificação, processaremos sua solicitação dentro do prazo legal
de 15 dias.

Atenciosamente,
DPO — Lexend Scholar
privacidade@lexendscholar.com.br
```

### 8.3 Resposta — Acesso aos Dados

```
Assunto: [Lexend Scholar] Protocolo #[ID] — Seus dados pessoais

Olá, [Nome],

Sua solicitação de acesso aos dados foi processada. Em anexo você
encontra o relatório completo com:

• Dados cadastrais armazenados
• Finalidade de cada categoria de dado
• Com quem seus dados são compartilhados
• Prazo de retenção de cada categoria

Arquivo: dados-[nome]-[data].pdf (protegido por senha: [CPF sem pontuação])

Caso tenha alguma dúvida ou queira exercer outros direitos, entre em
contato pelo e-mail abaixo.

Atenciosamente,
DPO — Lexend Scholar
privacidade@lexendscholar.com.br
```

### 8.4 Resposta — Exclusão de Dados

```
Assunto: [Lexend Scholar] Protocolo #[ID] — Confirmação de exclusão

Olá, [Nome],

Confirmamos que os seguintes dados foram excluídos de nossos sistemas
em [data]:

• [Lista de dados excluídos]

[Se houver dados mantidos por obrigação legal:]
Os seguintes dados são mantidos por exigência legal e não podem ser
excluídos neste momento:
• [Lista de dados mantidos] — mantidos por [motivo] até [data]

Certificado de exclusão em anexo.

Caso tenha alguma dúvida, entre em contato.

Atenciosamente,
DPO — Lexend Scholar
privacidade@lexendscholar.com.br
```

### 8.5 Resposta — Portabilidade

```
Assunto: [Lexend Scholar] Protocolo #[ID] — Exportação dos seus dados

Olá, [Nome],

Seus dados foram exportados conforme solicitado. O arquivo está
disponível para download por 7 dias no link abaixo:

[Link seguro — expira em: data]

Formato: JSON / CSV
Conteúdo: [descrição do que está incluído]

Caso precise de outro formato ou tenha dúvidas sobre como usar os dados
em outro sistema, entre em contato.

Atenciosamente,
DPO — Lexend Scholar
privacidade@lexendscholar.com.br
```

### 8.6 Resposta — Negativa (com recursos)

```
Assunto: [Lexend Scholar] Protocolo #[ID] — Resposta à sua solicitação

Olá, [Nome],

Analisamos sua solicitação de [tipo] e, após avaliação, não é possível
atendê-la pelos seguintes motivos:

[Motivo fundamentado, ex.: "Os dados são mantidos por obrigação legal
prevista em [lei], pelo prazo de [X] anos."]

Você tem o direito de:
1. Solicitar revisão desta decisão respondendo este e-mail
2. Registrar reclamação na Autoridade Nacional de Proteção de Dados (ANPD)
   — https://www.gov.br/anpd

Atenciosamente,
DPO — Lexend Scholar
privacidade@lexendscholar.com.br
```

---

## 9. Registro e Auditoria de DSARs

Todas as solicitações devem ser registradas na planilha/sistema de controle de DSARs com:

| Campo | Exemplo |
|-------|---------|
| ID do protocolo | DSAR-2026-001 |
| Data de recebimento | 2026-04-12 |
| Nome do titular | João da Silva |
| Tipo de solicitação | Acesso |
| Status | Concluído |
| Data de conclusão | 2026-04-25 |
| Ação realizada | Relatório PDF enviado |
| Responsável | DPO |

Registros de DSARs devem ser mantidos por **5 anos** para fins de auditoria e demonstração de conformidade com a ANPD.

---

## 10. Reclamações à ANPD

Se um titular não estiver satisfeito com a resposta do Lexend Scholar, pode registrar reclamação na ANPD:
- **Portal da ANPD:** https://www.gov.br/anpd/pt-br
- **Prazo da ANPD para análise:** conforme regulamentação vigente
- **O Lexend Scholar cooperará** com qualquer investigação da ANPD, fornecendo documentação e evidências solicitadas.

---

*Documento a ser revisado anualmente ou após alterações legislativas. Responsável: DPO.*
*Versão 1.0 — 2026-04-12*
