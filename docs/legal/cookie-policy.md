# Cookie Policy — Lexend Scholar

**Versão:** 1.0
**Data de vigência:** 12 de abril de 2026
**Última atualização:** 12 de abril de 2026

---

## 1. O que são Cookies

Cookies são pequenos arquivos de texto armazenados no dispositivo do usuário por um site ou aplicativo web. Eles permitem que o site reconheça o dispositivo em visitas futuras, mantenha sessões ativas e colete informações de uso.

---

## 2. Cookies Utilizados pelo Website Lexend Scholar

### 2.1. Cookies Estritamente Necessários

Estes cookies são indispensáveis para o funcionamento do website e da Plataforma. Não requerem consentimento (art. 4º, III, LGPD — dados tratados para fins legítimos do responsável).

| Nome do Cookie | Finalidade | Duração | Tipo |
|----------------|-----------|---------|------|
| `ls_session` | Mantém a sessão autenticada do usuário na Plataforma SaaS | Sessão (expiração ao fechar o navegador) | Primeira parte |
| `csrf_token` | Proteção contra ataques CSRF (Cross-Site Request Forgery) | Sessão | Primeira parte |
| `cookies_accepted` | Registra a preferência de consentimento do usuário para cookies analíticos | 365 dias | Primeira parte |

### 2.2. Cookies Analíticos (Requerem Consentimento)

Utilizamos o **Plausible Analytics** — uma solução de analytics de código aberto, sem uso de cookies de terceiros, sem coleta de dados pessoais identificáveis (sem PII), sem fingerprinting e em conformidade com a LGPD e GDPR por design.

| Nome | Finalidade | Duração | Tipo | Dados Coletados |
|------|-----------|---------|------|----------------|
| Plausible Analytics (script) | Medir visualizações de páginas, origem do tráfego e comportamento agregado de navegação no website público | N/A (não usa cookies próprios; usa contagem por sessão no servidor) | Terceiro (Plausible.io) | URL da página, referenciador, tipo de dispositivo, país — todos anonimizados e agregados; sem IP armazenado |

**Nota importante:** O Plausible Analytics não utiliza cookies de rastreamento no dispositivo do usuário. O script é carregado apenas quando o usuário aceita cookies analíticos através do banner de consentimento. Os dados são processados pela Plausible Analytics OÜ (Estônia/UE), sob adequação GDPR.

### 2.3. Cookies de Marketing / Publicidade

A Lexend Scholar **não utiliza** cookies de publicidade, retargeting ou rastreamento comportamental de terceiros (ex.: Google Ads, Meta Pixel, etc.).

---

## 3. Cookies na Plataforma SaaS (Área Logada)

A Plataforma SaaS (app.lexendscholar.com.br) utiliza **exclusivamente cookies de sessão estritamente necessários** (`ls_session`, `csrf_token`). Não há cookies analíticos ou de terceiros na área autenticada da aplicação, garantindo privacidade adicional dos dados dos usuários e alunos.

---

## 4. Gerenciamento de Consentimento

### 4.1. Banner de Consentimento

Ao acessar o website da Lexend Scholar pela primeira vez, o usuário verá um banner de consentimento de cookies no rodapé da página. O usuário pode:

- **Aceitar:** Consente com o carregamento do script Plausible Analytics. A preferência é salva em `localStorage` com a chave `cookies_accepted=true`.
- **Recusar:** O script Plausible não é carregado. A preferência é salva em `localStorage` com a chave `cookies_accepted=false`.

### 4.2. Como Alterar suas Preferências

O usuário pode alterar sua preferência a qualquer momento:

- **Via navegador:** Limpar os dados de `localStorage` e cookies do site nas configurações do navegador
- **Via contato:** Enviar solicitação para dpo@lexendscholar.com.br

### 4.3. Configurações do Navegador

Os usuários também podem configurar seus navegadores para bloquear ou excluir cookies. Consulte a documentação do seu navegador:

- [Google Chrome](https://support.google.com/chrome/answer/95647)
- [Mozilla Firefox](https://support.mozilla.org/kb/cookies-information-websites-store-on-your-computer)
- [Apple Safari](https://support.apple.com/guide/safari/manage-cookies-sfri11471/mac)

**Atenção:** Bloquear cookies estritamente necessários poderá impedir o funcionamento correto da Plataforma.

---

## 5. Base Legal para Uso de Cookies

| Categoria | Base Legal (LGPD) |
|-----------|------------------|
| Estritamente necessários | Legítimo interesse do controlador (art. 7º, IX) — essenciais para prestação do serviço |
| Analíticos (Plausible) | Consentimento do titular (art. 7º, I) — opcional, coletado via banner |

---

## 6. Alterações nesta Política

Esta Política pode ser atualizada periodicamente. Alterações materiais serão comunicadas via aviso no website com antecedência mínima de **15 dias**.

---

## 7. Contato

Para dúvidas sobre cookies ou exercício de direitos: **dpo@lexendscholar.com.br**

---

*Lexend Educação Ltda. (Lexend Scholar) — Todos os direitos reservados.*
