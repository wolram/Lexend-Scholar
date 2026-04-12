# COPPA Assessment — Lexend Scholar

**Versão:** 1.0
**Data:** 12 de abril de 2026
**Aplicável a:** Plataforma SaaS Lexend Scholar (web e iOS)

---

## 1. O que é COPPA e Quando se Aplica

### 1.1. Definição

O **Children's Online Privacy Protection Act (COPPA)** é uma lei federal dos Estados Unidos da América (15 U.S.C. §§ 6501–6506), regulamentada pela Federal Trade Commission (FTC), que estabelece obrigações para operadores de websites e serviços online que coletam dados pessoais de crianças menores de 13 anos.

### 1.2. Âmbito de Aplicação

O COPPA se aplica quando **pelo menos uma** das seguintes condições é verdadeira:

| Condição | Descrição |
|----------|-----------|
| **Directed to children** | O site ou serviço é primariamente dirigido a crianças menores de 13 anos, com base em conteúdo, linguagem visual, uso de personagens animados ou funcionalidades voltadas a esse público |
| **Actual knowledge** | O operador tem conhecimento real (actual knowledge) de que está coletando dados pessoais de uma criança menor de 13 anos |
| **Mixed audience com conhecimento** | Site de público geral que, sabendo que um usuário é menor de 13 anos, coleta seus dados |

### 1.3. Obrigações sob o COPPA (quando aplicável)

Para operadores sujeitos ao COPPA, as principais obrigações são:
- Publicar política de privacidade clara sobre práticas de coleta de dados de crianças
- Obter **consentimento parental verificável** antes de coletar dados pessoais de menores de 13 anos
- Dar aos pais controle sobre os dados coletados (acesso, correção, exclusão)
- Manter confidencialidade, segurança e integridade dos dados de crianças
- Não condicionar participação no serviço à obtenção de mais dados do que o necessário

### 1.4. Aplicabilidade Extraterritorial

O COPPA é lei americana. Sua aplicabilidade extraterritorial (a empresas brasileiras) ocorre quando o serviço é:
- Disponibilizado a usuários nos Estados Unidos, ou
- Acessado por crianças americanas

O Lexend Scholar é um produto para o mercado brasileiro, sem presença ou marketing direcionado aos EUA. Ainda assim, este assessment é relevante para:
1. Conformidade com as diretrizes da Apple App Store (que aplicam COPPA globalmente)
2. Adoção de boas práticas equivalentes exigidas pela LGPD (Art. 14)
3. Preparação para eventual expansão internacional

---

## 2. Análise do Lexend Scholar sob o COPPA

### 2.1. O Lexend Scholar é "Directed to Children"?

**Resposta: NÃO.**

A FTC utiliza os seguintes fatores para determinar se um serviço é "directed to children":

| Fator da FTC | Lexend Scholar | Análise |
|-------------|---------------|---------|
| Tema visual e conteúdo | Interface profissional B2B, terminologia educacional-administrativa | Não directed |
| Linguagem do conteúdo | Linguagem técnica/profissional, sem simplificação infantil | Não directed |
| Música e animações | Nenhuma animação ou conteúdo de entretenimento infantil | Não directed |
| Celebridades ou influenciadores de apelo infantil | Nenhum | Não directed |
| Publicidade voltada a crianças | Sem publicidade | Não directed |
| Evidência empírica sobre a base de usuários | Usuários cadastrados são adultos profissionais (diretores, secretários, professores) | Não directed |
| Modelo de negócio B2B | Contratação por CNPJ escolar, não por consumidor individual | Não directed |

**Conclusão: O Lexend Scholar NÃO é um serviço "directed to children" segundo os critérios da FTC.**

### 2.2. O Lexend Scholar Coleta Dados de Crianças Diretamente?

**Resposta: NÃO.**

O modelo de dados do Lexend Scholar segue este fluxo:

```
Responsável Legal / Escola
        |
        | (autoriza e assina contrato)
        v
Escola (Controladora de Dados - CNPJ)
        |
        | (profissionais adultos cadastram dados via interface profissional)
        v
Lexend Scholar Platform (Operadora)
        |
        | (armazena dados de gestão escolar)
        v
Dados do Aluno (cadastrado pela Escola, nunca pelo próprio aluno)
```

Os alunos menores de idade:
- **Nunca criam contas** no Lexend Scholar
- **Nunca fazem login** na plataforma
- **Nunca interagem diretamente** com a interface
- Têm seus dados gerenciados exclusivamente por profissionais adultos autorizados

### 2.3. Existe "Actual Knowledge" de Coleta de Dados de Menores de 13 Anos?

**Análise:** Sim — a Lexend Scholar tem conhecimento de que dados de alunos menores de 13 anos são cadastrados na plataforma pelas Escolas. No entanto, esse conhecimento é relevante para fins do COPPA apenas se o operador estiver coletando dados **diretamente das crianças** ou se o serviço for "directed to children".

Como o Lexend Scholar não coleta dados diretamente de menores e não é "directed to children", o "actual knowledge" neste contexto não aciona as obrigações do COPPA.

**Analogia legal:** Um sistema de RH que armazena dados de funcionários menores de idade não se torna sujeito ao COPPA porque os funcionários não interagem diretamente com o sistema — os dados são inseridos por administradores adultos.

---

## 3. Conclusão Legal

| Questão | Resposta | Fundamento |
|---------|----------|-----------|
| O Lexend Scholar é "directed to children"? | **Não** | Usuários diretos são adultos profissionais; conteúdo e modelo B2B são exclusivamente profissionais |
| O Lexend Scholar coleta dados diretamente de crianças menores de 13 anos? | **Não** | Dados são sempre inseridos por adultos autorizados (secretários, diretores) |
| O COPPA se aplica ao Lexend Scholar? | **Não diretamente** | Ausência dos dois critérios principais de aplicabilidade |
| O Lexend Scholar deve adotar proteções equivalentes ao COPPA? | **Sim** | Por exigência da LGPD (Art. 14) e das diretrizes da Apple App Store |

**O Lexend Scholar não está sujeito às obrigações do COPPA.** Contudo, por boa prática e conformidade com a LGPD e com as diretrizes da Apple, implementamos proteções equivalentes descritas na Seção 4.

---

## 4. Proteções Implementadas (Equivalentes COPPA / LGPD Art. 14)

Apesar de não estar diretamente sujeito ao COPPA, o Lexend Scholar implementa as seguintes proteções específicas para dados de alunos menores de idade:

### 4.1. Sem Publicidade

- Nenhuma forma de publicidade — comportamental, contextual ou direcionada — é exibida na Plataforma ou usa dados de alunos
- Nenhuma SDK de publicidade de terceiros é integrada ao app iOS ou à aplicação web
- Dados de alunos nunca são compartilhados com redes de publicidade

### 4.2. Sem Analytics em Dados de Alunos

- Ferramentas de analytics (ex.: Plausible) operam exclusivamente no website público e nunca processam dados de alunos
- A área logada da Plataforma não executa analytics de terceiros
- Logs internos de auditoria são de uso exclusivo para segurança e conformidade, nunca para perfilamento

### 4.3. Isolamento por `school_id` (Row Level Security)

- Todos os dados de alunos são isolados por `school_id` via Row Level Security (RLS) no banco de dados Supabase
- Um usuário autenticado de uma escola jamais pode acessar dados de alunos de outra escola
- Queries sem `school_id` retornam conjunto vazio por design (política de segurança default-deny)

### 4.4. Consentimento do Responsável Legal (LGPD Art. 14)

- A Escola (Controladora) é contratualmente obrigada a obter consentimento específico dos responsáveis legais para cadastro de alunos menores de 13 anos
- Essa obrigação está documentada nos Termos de Uso (Seção 7) e na Política de Privacidade (Seção 5.2)

### 4.5. Retenção Limitada e Exclusão Segura

- Dados de alunos são retidos por no máximo 5 anos após o encerramento do contrato com a Escola
- Após o período de retenção, os dados são excluídos de forma segura com sobrescrita

### 4.6. Sem Perfis Comportamentais de Alunos

- O Lexend Scholar não cria perfis comportamentais ou psicográficos de alunos
- Dados acadêmicos (notas, frequência) são usados exclusivamente para fins de gestão educacional e nunca para inferência comportamental, publicidade ou venda a terceiros

---

## 5. Posição em Relação à LGPD (Art. 14)

A LGPD, no Art. 14, estabelece que o tratamento de dados pessoais de crianças e adolescentes deve ser realizado:
- No **melhor interesse** da criança ou adolescente
- Com **consentimento específico e destacado** de ao menos um dos pais ou responsável legal, para crianças menores de 13 anos
- Sem condicionamento de qualquer serviço ao fornecimento de dados além do estritamente necessário

O Lexend Scholar está em conformidade com o Art. 14 porque:
1. O tratamento de dados de alunos é feito em nome da Escola, com finalidade educacional legítima
2. A Escola, como Controladora, é responsável por obter e manter o consentimento dos responsáveis
3. Não há condicionamento de serviços ao fornecimento de dados além dos necessários para a gestão escolar

---

## 6. Ações Recomendadas para Manutenção da Conformidade

| Ação | Responsável | Periodicidade |
|------|------------|--------------|
| Revisar este assessment a cada atualização significativa da plataforma | DPO + Legal | A cada release major |
| Verificar que nenhuma SDK nova integra analytics de alunos | Engineering Lead | A cada sprint |
| Auditar políticas de RLS do banco de dados | DBA / Supabase Admin | Trimestral |
| Atualizar Privacy Nutrition Labels no App Store Connect | Product Owner | A cada mudança de coleta de dados |
| Comunicar Escolas sobre suas obrigações de consentimento (LGPD Art. 14) | Customer Success | Onboarding + anual |

---

## 7. Referências

- [FTC — COPPA Rule](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa)
- [FTC — Six-Step Compliance Plan for Your Business](https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy)
- [FTC — "Mixed Audience" and COPPA](https://www.ftc.gov/tips-advice/business-center/guidance/complying-coppa-frequently-asked-questions)
- LGPD — Lei nº 13.709/2018, Art. 14 (Tratamento de dados de crianças e adolescentes)
- [ANPD — Regulamento de Proteção de Dados de Crianças e Adolescentes](https://www.gov.br/anpd)
- docs/legal/apple-dados-menores.md — Análise de conformidade Apple Developer Program

---

*Lexend Educação Ltda. (Lexend Scholar) — Documento interno de conformidade. Não constitui aconselhamento jurídico.*
