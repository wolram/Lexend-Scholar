# LS-175 — Configurar Internal Testing Track + Closed Testing (Google Play)

## Visão Geral dos Tracks

O Google Play Console oferece 4 tracks de distribuição. O Lexend Scholar usará 3 deles:

```
Internal Testing → Closed Testing (Alpha) → Production
                         ↓
                  [Escolas Piloto]
```

---

## 1. Internal Testing Track

### Configuração

| Parâmetro | Valor |
|-----------|-------|
| Nome do track | Internal testing |
| Máximo de testers | 100 (limite Google) |
| Aprovação necessária | Não (distribuição imediata) |
| Disponibilidade | Imediata após upload do APK/AAB |

### Lista de Testers (Equipe Interna)

Criar grupo de e-mails no Play Console → Configuração → Grupos de teste internos:

**Grupo: "Equipe Lexend"**
Adicionar e-mails corporativos @lexend.com.br de:
- Time de Engenharia (todos os devs Android e iOS)
- Time de QA
- Product Manager e Product Owner
- Time de Design (para validação de UI)
- Diretores e C-Level

### Processo de Distribuição Interna

```
1. Dev faz build de release (./gradlew bundleRelease)
2. Assinar AAB com keystore de produção
3. Upload no Play Console → Internal testing → Criar nova versão
4. Adicionar release notes (pt-BR): "Versão interna X.X — alterações: ..."
5. Salvar e publicar → disponível em ~1 minuto para testers
6. Notificar equipe via Slack #android-releases com link de opt-in
```

### Link de Opt-in Interno

```
https://play.google.com/apps/internaltest/[TOKEN_GERADO_PLAY_CONSOLE]
```

O link é gerado automaticamente pelo Play Console após a primeira publicação.

---

## 2. Closed Testing (Alpha) — Escolas Piloto

### Configuração

| Parâmetro | Valor |
|-----------|-------|
| Nome do track | Alpha - Escolas Piloto |
| Tipo | Closed testing (por e-mail) |
| Máximo de testers | Sem limite (por lista de e-mails) |
| Aprovação necessária | Não |
| Disponibilidade | 24–48h após upload |

### Critérios de Seleção das Escolas Piloto

| Critério | Requisito |
|----------|-----------|
| Porte da escola | 100–500 alunos |
| Localização | Preferencialmente SP e MG (maior base) |
| Engajamento | Responderam pesquisa de interesse no produto |
| Dispositivos | Mix de Android antigo (API 26+) e recente |
| Perfis necessários | Diretor + Secretária + ao menos 2 professores |

### Escolas Piloto Alvo (Primeira Rodada)

```
1. Colégio São Lucas - São Paulo, SP (~200 alunos)
2. Escola Pequeno Príncipe - Belo Horizonte, MG (~150 alunos)  
3. Centro Educacional Aurora - Campinas, SP (~300 alunos)
4. Instituto Santa Clara - Ribeirão Preto, SP (~120 alunos)
5. Colégio Montessori ABC - Santo André, SP (~180 alunos)
```

### Processo de Onboarding Beta

```
Semana -2: Contatar escolas, coletar lista de e-mails de usuários
Semana -1: Adicionar e-mails no Play Console → Closed testing → Gerenciar testers
Semana  0: Publicar AAB no Closed testing track
           Enviar e-mail personalizado com link de opt-in e guia de instalação
Semana +1: Sessão de feedback via Google Meet (1h por escola)
Semana +2: Coletar feedback estruturado via formulário
Semana +4: Decidir se promove para Production ou realiza novo ciclo
```

### Template de E-mail para Escolas Piloto

```
Assunto: Convite para Programa Beta — Lexend Scholar

Prezado(a) [Nome],

Você foi selecionado(a) para o programa de beta testing do Lexend Scholar, 
o sistema de gestão escolar que vai transformar o dia a dia da [Escola]!

Para instalar a versão beta no seu dispositivo Android, clique no link abaixo:
[LINK_OPT-IN]

Precisamos do seu feedback sobre:
- Cadastro de alunos
- Registro de frequência  
- Geração de boletins
- Comunicação com responsáveis

Suporte durante o beta: beta@lexendscholar.com.br | WhatsApp: (11) 9999-9999

Obrigado por fazer parte desta jornada!
Equipe Lexend
```

---

## 3. Estrutura de Release Notes

### Template para Internal Testing

```
Versão [X.X.X] — Build [NNN]
Data: [DD/MM/YYYY]

Novidades:
• [Feature 1]
• [Feature 2]

Correções:
• [Bug fix 1]

Para testar:
1. [Passo de teste 1]
2. [Passo de teste 2]

Reportar bugs: #android-bugs no Slack ou criar issue no Linear
```

### Template para Closed Testing (Escolas Piloto)

```
Versão [X.X] — Atualização Beta
Data: [DD/MM/YYYY]

O que há de novo:
• [Descrição amigável de feature 1]
• [Descrição amigável de feature 2]

O que foi melhorado:
• [Melhoria de performance/UX]

Como nos ajudar:
• Tente [ação específica] e nos diga como foi
• Reportar problemas: beta@lexendscholar.com.br
```

---

## 4. Promoção entre Tracks

### Critérios para Promover de Internal → Closed Testing

- [ ] Zero crash rate em 24h de internal testing
- [ ] Todas as user stories do sprint testadas e aprovadas
- [ ] Smoke test manual executado (ver LS-171)
- [ ] Release notes em pt-BR finalizadas
- [ ] APK/AAB assinado com keystore de produção (não debug)

### Critérios para Promover de Closed → Production

- [ ] Feedback das escolas piloto analisado
- [ ] Bugs críticos reportados resolvidos
- [ ] Rating beta (Google Play feedback) > 4.0
- [ ] Crash rate < 1% na semana anterior
- [ ] Aprovação do Product Owner

---

## 5. Comandos e Configurações

### Assinar AAB para Upload

```bash
# Gerar release AAB
./gradlew bundleRelease

# Assinar com keystore
jarsigner -verbose \
  -sigalg SHA256withRSA \
  -digestalg SHA-256 \
  -keystore lexend-scholar-prod.keystore \
  app/build/outputs/bundle/release/app-release.aab \
  lexend-scholar-key-alias

# Verificar assinatura
jarsigner -verify -verbose app/build/outputs/bundle/release/app-release.aab
```

### Upload via Play Developer API (automação futura)

```bash
# Usando fastlane supply
fastlane supply \
  --aab app/build/outputs/bundle/release/app-release.aab \
  --track internal \
  --json_key play-store-credentials.json \
  --package_name com.lexend.scholar
```

---

## Referências

- [Google Play Testing Overview](https://developer.android.com/distribute/best-practices/launch/test-tracks)
- [Play Console — Manage Testers](https://support.google.com/googleplay/android-developer/answer/9845334)
- [Fastlane Supply](https://docs.fastlane.tools/actions/supply/)
- [Data Safety — LS-173](./LS-173-data-safety-play-store.md)
