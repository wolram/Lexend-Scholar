# Privacy Nutrition Labels — Lexend Scholar

Declaração completa de privacidade para o App Store Connect (Privacy — App Privacy).

> **Revisão obrigatória:** este documento deve ser aprovado pelo time Legal antes da submissão.  
> Última atualização: 2026-04-12

---

## 1. Mapa de Dados Coletados

### Categoria: Dados de Contato

| Tipo de dado | Coletado? | Used to Track You | Linked to You | Required |
|---|---|---|---|---|
| Nome | Sim | Não | Sim | Sim |
| Endereço de e-mail | Sim | Não | Sim | Sim |
| Número de telefone | Sim | Não | Sim | Não |
| Endereço físico | Sim | Não | Sim | Não |

**Justificativa:** Nome e e-mail são necessários para criação de conta e autenticação. Telefone e endereço são coletados para comunicação escola–família e registros cadastrais exigidos por lei.

---

### Categoria: Dados do Usuário (Conteúdo do App)

| Tipo de dado | Coletado? | Used to Track You | Linked to You | Required |
|---|---|---|---|---|
| E-mails / mensagens enviadas no app | Sim | Não | Sim | Não |
| Arquivos/documentos (boletins, documentos escolares) | Sim | Não | Sim | Não |

**Justificativa:** Comunicados internos e documentos escolares são gerados e armazenados para uso da instituição de ensino.

---

### Categoria: Dados Educacionais

| Tipo de dado | Coletado? | Used to Track You | Linked to You | Required |
|---|---|---|---|---|
| Notas e boletins | Sim | Não | Sim | Sim |
| Registro de frequência/presença | Sim | Não | Sim | Sim |
| Dados de matrícula e turma | Sim | Não | Sim | Sim |
| Ocorrências disciplinares | Sim | Não | Sim | Não |
| Histórico escolar | Sim | Não | Sim | Não |

**Justificativa:** Dados educacionais constituem a funcionalidade central do app. São coletados para gestão escolar, cumprimento de exigências pedagógicas e legais (LGPD Art. 7º, IV — execução de contrato).

---

### Categoria: Dados Financeiros

| Tipo de dado | Coletado? | Used to Track You | Linked to You | Required |
|---|---|---|---|---|
| Informações de pagamento (status de mensalidades) | Sim | Não | Sim | Não |
| Histórico de transações (cobranças escolares) | Sim | Não | Sim | Não |

**Justificativa:** Necessário para controle de inadimplência e geração de relatórios financeiros da instituição. Dados de cartão de crédito NÃO são coletados diretamente pelo app.

---

### Categoria: Identificadores

| Tipo de dado | Coletado? | Used to Track You | Linked to You | Required |
|---|---|---|---|---|
| ID do usuário (UUID gerado pelo app) | Sim | Não | Sim | Sim |
| Device token (APNs — para push notifications) | Sim | Não | Sim | Não |

**Justificativa:** O ID do usuário é necessário para autenticação e sincronização de dados via Supabase. O device token APNs é necessário exclusivamente para entrega de push notifications (comunicados, alertas de frequência, cobranças); não é usado para rastreamento cross-app.

---

### Categoria: Dados de Uso

| Tipo de dado | Coletado? | Used to Track You | Linked to You | Required |
|---|---|---|---|---|
| Interações com o app (páginas visitadas, funcionalidades usadas) | Sim | Não | Sim | Não |
| Dados de diagnóstico (crash logs) | Sim | Não | Não | Não |

**Justificativa:** Dados de uso são utilizados para melhoria do produto e análise de adoção de funcionalidades. Crash logs são coletados de forma anônima via instrumentação padrão Apple.

---

### Dados NÃO coletados

| Tipo | Motivo |
|------|--------|
| Localização GPS | App não usa localização |
| Contatos do dispositivo | App não acessa agenda telefônica |
| Fotos/câmera (automático) | Acesso somente sob demanda do usuário (upload de foto de perfil) |
| Histórico de navegação | App não usa WebViews com rastreamento |
| Dados de saúde/biometria | Fora do escopo do app |
| Dados de publicidade (IDFA) | App não usa redes de anúncios |

---

## 2. Resumo para App Store Connect

### Data Used to Track You
**Nenhum dado** é usado para rastrear o usuário em apps ou sites de terceiros (IDFA não utilizado, sem SDKs de publicidade).

> No App Store Connect: marcar **"We do not collect data"** para esta categoria, OU se houver analytics: selecionar apenas "Analytics > App Interactions" com "Not Linked to You" e "Not Used to Track You".

### Data Linked to You
Os seguintes tipos devem ser declarados como **Linked to You**:

| Categoria App Store | Subcategoria |
|--------------------|--------------|
| Contact Info | Name |
| Contact Info | Email Address |
| Contact Info | Phone Number |
| Contact Info | Physical Address |
| Identifiers | User ID |
| Identifiers | Device ID (APNs token) |
| Usage Data | Product Interaction |
| Sensitive Info | *(Dados educacionais de menores — ver nota abaixo)* |
| Financial Info | Other Financial Info |
| User Content | Emails or Text Messages |
| User Content | Other User Content (documentos escolares) |

> **Nota sobre dados de menores:** A Apple classifica dados educacionais de crianças menores de 13 anos como dados sensíveis. Declarar na seção "Sensitive Info > Other Sensitive Info" com "Linked to You" e "Required".

### Data Not Linked to You
| Categoria App Store | Subcategoria |
|--------------------|--------------|
| Diagnostics | Crash Data |
| Diagnostics | Performance Data |

---

## 3. Passo a Passo — Preenchimento no App Store Connect

1. Acesse [App Store Connect](https://appstoreconnect.apple.com) → seu app → **App Privacy**
2. Clique em **Get Started** (ou **Edit** se já preenchido)
3. Responda: *"Do you collect data from this app?"* → **Yes**
4. Para cada categoria de dados:
   a. Selecione o **tipo de dado**
   b. Indique a **finalidade** (App Functionality, Analytics, Developer's Advertising, etc.)
   c. Responda se é **Linked to Identity** (vinculado ao usuário)
   d. Responda se é **Used for Tracking** (sempre "No" para Lexend Scholar)
5. Revise o resumo gerado (Privacy Nutrition Label preview)
6. Clique em **Publish** — as labels ficam visíveis na App Store após aprovação

### Finalidades por tipo de dado (mapeamento)

| Dado | Finalidade no App Store Connect |
|------|---------------------------------|
| Nome, e-mail | App Functionality |
| Device token APNs | App Functionality |
| Notas, frequência | App Functionality |
| Dados financeiros | App Functionality |
| Interações de uso | Analytics |
| Crash logs | App Functionality, Analytics |

---

## 4. Conformidade LGPD

O app opera sob a **Lei Geral de Proteção de Dados (Lei 13.709/2018)**:

- **Base legal principal:** Execução de contrato (Art. 7º, V) — contrato entre escola e família
- **Dado sensível:** Dados educacionais de crianças (Art. 11) — tratamento com consentimento explícito dos responsáveis
- **Retenção:** Dados mantidos enquanto durar o vínculo escolar + período legal de guarda de documentos (5 anos mínimo)
- **DPO:** Indicar responsável pelo tratamento de dados na Política de Privacidade
- **Direitos do titular:** Acesso, correção e exclusão disponíveis via solicitação ao suporte

---

## Referências

- [App Store Connect Help — App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Apple Privacy Nutrition Labels](https://developer.apple.com/app-store/app-privacy-details/)
- [LGPD — Lei 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/L13709.htm)
- [COPPA — Children's Online Privacy Protection Act](https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa) (se app disponível nos EUA)
