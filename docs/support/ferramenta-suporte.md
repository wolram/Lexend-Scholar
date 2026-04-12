# Ferramenta de Suporte: Intercom vs Crisp

## Resumo Executivo

Após análise comparativa, **recomendamos o Crisp** como ferramenta de suporte do Lexend Scholar, especialmente para a fase inicial como SaaS B2B com equipe pequena (1-3 pessoas de suporte).

---

## Comparativo: Intercom vs Crisp

| Critério | Intercom | Crisp |
|---|---|---|
| **Plano gratuito** | Não (trial 14 dias) | Sim (2 agentes, recursos básicos) |
| **Preço inicial pago** | ~$74/mês (Starter) | $25/mês (Pro, 4 agentes) |
| **Widget de chat** | Sim | Sim |
| **Base de conhecimento** | Sim (pago) | Sim (incluído no Pro) |
| **Email de suporte** | Sim | Sim |
| **Integração com Linear** | Via Zapier/webhook | Via Zapier/webhook |
| **Chatbot / automações** | Avançado | Básico a intermediário |
| **Suporte a múltiplos idiomas** | Sim | Sim (PT-BR incluído) |
| **iOS SDK** | Sim | Sim |
| **Android SDK** | Sim | Sim |
| **Analytics** | Avançado | Básico |
| **Curva de aprendizado** | Alta | Baixa |
| **Ideal para** | Scale-ups com equipe dedicada | Early-stage e pequenas equipes |

---

## Recomendação: Crisp

### Por que Crisp?

1. **Custo-benefício superior**: Crisp Pro custa $25/mês vs $74/mês do Intercom Starter — 3x mais barato com funcionalidades suficientes para o estágio atual.
2. **Plano gratuito funcional**: Permite começar sem custo com 2 agentes enquanto valida o produto.
3. **Configuração rápida**: Em menos de 30 minutos é possível ter o chat funcionando no website e no app.
4. **Help Center integrado**: A base de conhecimento já está incluída no plano Pro, sem custo adicional.
5. **PT-BR nativo**: Interface e widget em português brasileiro.
6. **Webhooks robustos**: Permite integração com Linear para criação automática de tickets.

### Quando migrar para o Intercom?
Considere migrar quando:
- MRR ultrapassar R$30.000/mês
- Equipe de suporte tiver 3+ agentes dedicados
- Necessitar de automações avançadas de onboarding (Product Tours)
- Volume de tickets ultrapassar 500/mês

---

## Passo a Passo de Configuração do Crisp

### 1. Criar conta
1. Acesse [crisp.chat](https://crisp.chat)
2. Clique em **Sign up free**
3. Preencha com email do domínio (@lexendscholar.com)
4. Confirme email e acesse o dashboard

### 2. Configurar o workspace
1. Em **Settings > Website**, defina o nome: **Lexend Scholar Suporte**
2. Upload do logo (PNG 120x120px recomendado)
3. Defina o horário de atendimento: **Seg-Sex 9h-18h (BRT)**
4. Configure a mensagem de ausência para fora do horário:
   ```
   Olá! Estamos fora do horário de atendimento (Seg-Sex 9h-18h).
   Deixe sua mensagem e respondemos em até 4 horas no próximo dia útil.
   ```

### 3. Configurar o widget de chat

#### Instalação no website (HTML)
```html
<!-- Adicionar antes do </body> no website -->
<script type="text/javascript">
  window.$crisp=[];
  window.CRISP_WEBSITE_ID="SEU-WEBSITE-ID-AQUI";
  (function(){
    d=document;
    s=d.createElement("script");
    s.src="https://client.crisp.chat/l.js";
    s.async=1;
    d.getElementsByTagName("head")[0].appendChild(s);
  })();
</script>
```

#### Personalização do widget
Em **Settings > Chatbox**:
- Cor principal: `#1A56DB` (azul Lexend Scholar)
- Posição: Canto inferior direito
- Texto de saudação: "Olá! Como podemos ajudar sua escola hoje?"
- Trigger automático (após 30s na página de preços): "Tem dúvidas sobre os planos? Converse conosco!"

### 4. Configurar SDK no app iOS

```swift
// AppDelegate.swift ou inicialização no SwiftUI
import CrispSDK

// No app init:
Crisp.initialize(websiteID: "SEU-WEBSITE-ID-AQUI")

// Para identificar usuário logado:
Crisp.setUserEmail("diretor@escola.com.br")
Crisp.setUserNickname("Maria Silva")
Crisp.setSessionString("school_id", "abc123")
Crisp.setSessionString("plan", "pro")

// Para abrir o chat programaticamente:
CrispViewController.show(in: self)
```

### 5. Configurar o Help Center
1. Em **Plugins > Help Center**, ativar o módulo
2. URL do help center: `help.lexendscholar.com` (configurar CNAME no DNS)
3. Criar categorias iniciais:
   - Primeiros Passos
   - Para Diretores
   - Para Professores
   - Para a Secretaria
   - Para Responsáveis
   - Financeiro e Cobranças
   - Problemas Técnicos

### 6. Configurar emailbox
1. Em **Settings > Email**, configurar email de suporte: `suporte@lexendscholar.com`
2. Ativar encaminhamento para o Crisp inbox

### 7. Configurar agentes e equipes
1. Convidar co-fundadores como agentes
2. Criar equipes: **Suporte Técnico** e **Comercial**
3. Definir regras de roteamento (ver `sla-tiers.md`)

### 8. Configurar automações básicas
- **Tag automático**: Mencionar "bug" → tag `bug`, assignar para Suporte Técnico
- **Tag automático**: Mencionar "preço" ou "plano" → tag `comercial`, assignar para Comercial
- **Resposta automática**: Primeiro contato fora do horário → mensagem de ausência

---

## Checklist de Go-Live

- [ ] Conta Crisp criada com email corporativo
- [ ] Logo e cores configurados
- [ ] Widget instalado no website (todas as páginas)
- [ ] SDK integrado no app iOS
- [ ] Email de suporte configurado
- [ ] Help Center com URL personalizada
- [ ] Ao menos 5 artigos publicados no Help Center
- [ ] Webhook do Crisp configurado para o Linear (ver `linear-integration.md`)
- [ ] Equipe treinada no dashboard do Crisp
- [ ] Teste de chat funcionando

---

## Recursos Úteis

- [Documentação Crisp](https://docs.crisp.chat)
- [Crisp iOS SDK GitHub](https://github.com/crisp-im/crisp-sdk-ios)
- [Crisp Webhooks Docs](https://docs.crisp.chat/references/rest-api/v1/#webhooks)
