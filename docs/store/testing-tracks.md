# Testing Tracks — Google Play Console

> Issue: LS-175 | Configurar internal testing track + closed testing

---

## Internal Testing (até 100 testers)

### Características
- Sem revisão da Google — disponível em **minutos** após upload
- Ideal para: equipe interna, stakeholders, investidores, demonstrações rápidas
- Requer: APK ou AAB assinado com keystore de produção

### Como Configurar
1. Acesse **Google Play Console → [App] → Testing → Internal Testing**
2. Clique em **Create new release**
3. Faça upload do AAB assinado
4. Em **Testers**, clique em **Create email list**
5. Nome sugerido da lista: `Equipe Interna Lexend Scholar`
6. Adicione emails (até 100)
7. Compartilhe o link de opt-in com os testers: `play.google.com/apps/internaltest/...`

### Quem Adicionar
- Equipe de desenvolvimento
- Product Manager e Designer
- Fundadores e C-level
- Investidores e advisors (via link separado)

### Release Notes (Internal)
```
[INTERNAL] Build {versão} — {data}

Novidades desta build:
- {lista de mudanças}

Testar especialmente:
- {área de foco}

Reportar bugs: issues no Linear ou WhatsApp do time
```

---

## Closed Testing / Alpha (até 2.000 testers por email)

### Características
- Revisão da Google necessária (~1-3 dias úteis)
- Controle por lista de emails aprovados
- Feedback estruturado via formulário externo

### 5 Escolas Piloto Convidadas
- Recrutamento via formulário em **lexendscholar.com.br/beta**
- Critérios de seleção:
  - Escola com 50–300 alunos (escopo representativo)
  - Diretor ou coordenador engajado como ponto focal
  - Disposição para fornecer feedback estruturado

### Como Configurar
1. Acesse **Google Play Console → Testing → Closed Testing**
2. Crie uma nova faixa chamada `Alpha - Escolas Piloto`
3. Adicione emails das escolas participantes
4. Configure o formulário de feedback (link abaixo)

### Formulário de Feedback Estruturado (Google Form)

**Link:** criar em forms.google.com com as perguntas abaixo

**NPS (Net Promoter Score)**
- "Em uma escala de 0 a 10, o quanto você recomendaria o Lexend Scholar para outra escola?"

**5 Perguntas Abertas:**
1. Como foi sua experiência com o registro de **frequência**? O que funcionou bem? O que foi difícil?
2. Você conseguiu gerar e enviar **boletins** em PDF? Houve algum problema?
3. Você usou o módulo **financeiro**? O que facilitou ou dificultou?
4. Como foi o processo de **onboarding** (cadastro inicial, importação de alunos)?
5. Qual funcionalidade você mais sentiu falta ou gostaria que fosse diferente?

### Duração do Closed Testing
- **Mínimo:** 4 semanas
- **Check-in:** reunião de feedback quinzenal com as escolas piloto (30 min, Google Meet)

---

## Open Beta (ilimitado, público)

### Características
- Qualquer usuário pode se inscrever via Play Store
- Ainda separado da produção
- Útil para aumentar base de dados e reviews antes do lançamento oficial

---

## Critérios de Promoção entre Tracks

| Transição | Critério | Responsável | Ferramenta de Verificação |
|-----------|---------|-------------|--------------------------|
| Internal → Closed Testing | Zero crashes P0, APK assinado com keystore de produção, funcionalidades core testadas (auth, frequência, boletim, financeiro) | Tech Lead | Firebase Crashlytics |
| Closed Testing → Open Beta | NPS > 7 (média das escolas piloto), zero bugs P1 abertos no Linear, rating interno ≥ 4.0 | Product Manager | Linear + Google Form |
| Open Beta → Produção | 50+ usuários ativos, crash-free rate ≥ 99.5%, rating público ≥ 4.2 estrelas, sem regressões de performance | Tech Lead + PO | Firebase + Play Console |

---

## Templates de Release Notes (pt-BR)

### Internal Testing
```
🔧 [INTERNO] Versão {X.Y.Z} — Build {data}

O que mudou:
- {mudança 1}
- {mudança 2}

Foco de teste: {área específica}
Reportar no Linear: linear.app/lexend/...
```

### Closed Testing (Escolas Piloto)
```
Olá, parceiros beta! 👋

Versão {X.Y.Z} disponível com melhorias baseadas no feedback de vocês:

✅ Corrigido: {bug relatado}
✨ Novo: {funcionalidade adicionada}
⚡ Melhorado: {melhoria de performance/UX}

Continuem testando e enviando feedback pelo formulário:
[link do formulário]

Obrigado por ajudar a construir o melhor app de gestão escolar do Brasil! 🇧🇷
```

### Open Beta
```
Versão {X.Y.Z} — Novidades

O que há de novo:
• {funcionalidade principal}
• {melhoria importante}

Correções:
• {bug corrigido 1}
• {bug corrigido 2}

Feedback? suporte@lexendscholar.com.br
```

### Produção
```
Versão {X.Y.Z}

Novidades:
• {funcionalidade principal — orientada a benefício}
• {melhoria — orientada a benefício}

Melhorias de desempenho e correções de bugs.

Dúvidas? suporte@lexendscholar.com.br
```
