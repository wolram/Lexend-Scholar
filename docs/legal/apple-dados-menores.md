# Apple Developer Program — Conformidade para Apps com Dados de Menores

**Versão:** 1.0
**Data:** 12 de abril de 2026
**Aplicável a:** Lexend Scholar iOS App (App Store)

---

## 1. Visão Geral

Este documento analisa os requisitos do Apple Developer Program relativos a aplicativos que envolvem dados de menores de idade, avalia sua aplicabilidade ao Lexend Scholar e define as ações necessárias para submissão e conformidade contínua na App Store.

---

## 2. Requisitos do Apple Developer Program para Apps com Dados de Menores

### 2.1. App Store Review Guidelines — Seção 1.3 (Kids Category)

A Apple define uma categoria especial chamada **"Kids"** para aplicativos primariamente direcionados a crianças menores de 13 anos. Apps na categoria Kids estão sujeitos a requisitos mais rígidos:

- **Sem publicidade de terceiros:** não é permitida publicidade comportamental ou de terceiros
- **Sem rastreamento de analytics de terceiros:** analytics que coletam dados pessoais são proibidos
- **Sem links externos:** links para websites externos são restritos (apenas mediante saída controlada com aviso)
- **Coleta de dados mínima:** apenas dados estritamente necessários para o funcionamento do app
- **Consentimento parental obrigatório:** qualquer coleta de dados pessoais de menores deve ser precedida de consentimento verificável do responsável legal
- **Privacy Nutrition Labels:** devem refletir com precisão todos os dados coletados

### 2.2. KIDSNET / COPPA — Implications para Apps Acessados por Crianças

O **Children's Online Privacy Protection Act (COPPA)** é a legislação federal americana que regula a coleta de dados de crianças menores de 13 anos. A Apple exige que apps que se enquadrem no escopo do COPPA estejam em conformidade com ele.

**Quando o COPPA se aplica:**
1. O app é "directed to children" (primariamente direcionado a crianças)
2. O app é de propósito geral (general audience) mas o operador tem conhecimento de que está coletando dados de menores de 13 anos

**Implicações práticas na App Store:**
- Apps que coletam dados de crianças de forma intencional e direta devem estar na categoria Kids
- Apps que permitem que crianças criem contas ou façam login diretamente são considerados "directed to children"
- Apps B2B com autenticação restrita a adultos profissionais não são tipicamente classificados como "directed to children"

### 2.3. App Privacy Report e Privacy Nutrition Labels (App Store Connect)

A Apple exige declaração detalhada no App Store Connect sobre:

- **Data Used to Track You:** dados usados para rastrear o usuário entre apps/websites
- **Data Linked to You:** dados coletados e vinculados à identidade do usuário
- **Data Not Linked to You:** dados coletados mas não vinculados ao usuário

---

## 3. Análise de Aplicabilidade ao Lexend Scholar

### 3.1. Perfil dos Usuários Diretos do App iOS

O aplicativo iOS do Lexend Scholar é destinado **exclusivamente a profissionais de educação**:

| Perfil de Usuário | Faixa Etária | Tipo |
|-------------------|--------------|------|
| Diretores | Adultos (18+) | Profissional |
| Secretários | Adultos (18+) | Profissional |
| Professores | Adultos (18+) | Profissional |

**Conclusão:** Os usuários diretos do app iOS são adultos. Crianças e adolescentes **não têm acesso** ao aplicativo — eles são apenas sujeitos dos dados gerenciados pelos profissionais.

### 3.2. Natureza dos Dados de Menores no App

Os dados de alunos menores de idade no Lexend Scholar:

- São **cadastrados por adultos** (secretários, diretores), não pelo próprio menor
- Nunca são inseridos diretamente por crianças ou adolescentes
- Não envolvem criação de conta pelo menor ou login do menor no app
- São tratados como dados funcionais de gestão escolar, equivalentes a um sistema de RH educacional

### 3.3. Classificação do App — "Directed to Children"?

**Resposta: NÃO.** O Lexend Scholar não é "directed to children" segundo os critérios da Apple e do COPPA:

| Critério | Lexend Scholar | Classificação |
|----------|---------------|--------------|
| Conteúdo visual/temático voltado a crianças | Não — interface profissional B2B | Não-directed |
| Personagens animados ou conteúdo infantil | Não | Não-directed |
| Crianças como usuários primários | Não — adultos profissionais | Não-directed |
| Publicidade voltada a crianças | Não há publicidade | Não-directed |
| Criação de conta pelo menor | Não há | Não-directed |

**Categoria correta na App Store:** Categoria **"Education"** ou **"Business"** — NÃO a categoria "Kids".

---

## 4. Recomendações de Conformidade

### 4.1. Sem Publicidade e Sem Analytics de Terceiros

Manter a política de:
- Nenhuma SDK de publicidade (AdMob, Meta Audience Network, etc.)
- Nenhum SDK de analytics que colete dados pessoais identificáveis de usuários (ex.: Firebase Analytics com dados vinculados ao usuário)
- Qualquer analytics deve ser de agregação anonimizada e sem PII

### 4.2. Modo Privado para Dados de Alunos

Implementar e documentar:
- Os dados de alunos nunca são exibidos fora do contexto da sessão autenticada
- Não há caching de dados de alunos no dispositivo além do necessário para funcionamento offline mínimo
- Dados locais em cache (se houver) devem ser criptografados usando o Keychain do iOS

### 4.3. Privacy Nutrition Labels — Declaração no App Store Connect

Com base nos dados coletados, declarar no App Store Connect:

**Data Linked to You (dados vinculados à identidade do usuário autenticado):**
- Name (nome do usuário)
- Email Address (e-mail de login)
- User ID (identificador da conta)

**Data Not Linked to You:**
- Diagnostics (crash reports — se usar ferramentas como Sentry com anonimização)

**Data NOT Collected:**
- No financial info collected by the app
- No location data
- No contacts
- No browsing history
- No health & fitness data
- No sensitive info

### 4.4. App Privacy Policy URL

A URL da Política de Privacidade deve ser informada no App Store Connect. Usar: `https://lexendscholar.com.br/legal/privacidade`

### 4.5. Age Rating

Configurar o age rating como **"4+"** (sem conteúdo restrito). Não selecionar configurações que impliquem conteúdo para adultos ou conteúdo assustador.

---

## 5. Checklist de Conformidade para Submissão na App Store

### 5.1. Antes da Submissão

- [ ] Confirmar que nenhum SDK de publicidade de terceiros está integrado ao app
- [ ] Confirmar que nenhum SDK de analytics com coleta de PII está ativo (ex.: Firebase Analytics sem anonimização)
- [ ] Verificar que o app **não** permite login ou criação de conta por menores de idade
- [ ] Confirmar que dados de alunos em cache local (se houver) são criptografados via iOS Keychain / Data Protection API
- [ ] Revisar e atualizar Privacy Nutrition Labels no App Store Connect para refletir os dados coletados
- [ ] Informar a URL da Política de Privacidade no App Store Connect
- [ ] Confirmar age rating como "4+"
- [ ] Confirmar que a categoria do app é "Education" ou "Business" (não "Kids")

### 5.2. No App Store Connect

- [ ] Privacy Policy URL preenchida e acessível publicamente
- [ ] Nutrition Labels preenchidas com precisão
- [ ] Nenhuma entidade de publicidade vinculada ao app
- [ ] Review notes explicando que o app é B2B para profissionais de educação, não para alunos menores

### 5.3. Revisão Contínua (Pós-Lançamento)

- [ ] Revisar Privacy Nutrition Labels sempre que uma nova SDK ou funcionalidade for adicionada
- [ ] Manter atualizada a Política de Privacidade a cada mudança relevante de tratamento de dados
- [ ] Verificar anualmente a conformidade com as Apple Developer Program License Agreement (DPLA)
- [ ] Monitorar atualizações das App Store Review Guidelines quanto a requisitos de privacidade

---

## 6. Referências

- [App Store Review Guidelines — Section 1.3 Kids](https://developer.apple.com/app-store/review/guidelines/#kids)
- [Apple — Privacy Best Practices](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
- [Apple — App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [COPPA — FTC](https://www.ftc.gov/business-guidance/privacy-security/childrens-privacy)
- LGPD — Art. 14: Tratamento de dados pessoais de crianças e adolescentes
- [ANPD — Resolução sobre dados de crianças e adolescentes](https://www.gov.br/anpd)

---

*Lexend Educação Ltda. (Lexend Scholar) — Documento interno de conformidade.*
