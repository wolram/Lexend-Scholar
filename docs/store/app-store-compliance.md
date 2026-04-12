# App Store Compliance — Lexend Scholar

Checklist de conformidade com as App Store Review Guidelines da Apple.

> Última revisão: 2026-04-12  
> Referência: [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## Legenda de Status

| Símbolo | Significado |
|---------|-------------|
| ✅ | Conforme |
| ⚠️ | Atenção / verificação necessária |
| ❌ | Não conforme / ação obrigatória |
| 🔲 | Não avaliado / pendente |

---

## Guideline 1 — Safety

### 1.1 — Objectionable Content
| Item | Status | Observação |
|------|--------|------------|
| App não contém conteúdo ofensivo, violento ou discriminatório | ✅ | App educacional |
| App não promove atividades ilegais | ✅ | |

### 1.3 — Kids Category
| Item | Status | Observação |
|------|--------|------------|
| App não coleta dados de crianças sem consentimento dos pais | ⚠️ | Verificar fluxo de onboarding: responsável (adulto) cria conta, não a criança |
| App não contém publicidade direcionada a menores | ✅ | Sem SDKs de anúncios |
| App não usa IDFA para crianças | ✅ | IDFA não utilizado |
| Links externos restritos se app for na categoria Kids | ⚠️ | Definir se app vai para categoria "Education" ou "Kids" |

> **Plano de ação:** Confirmar com Product que o target de uso direto é o **professor/gestor** (adulto), não o aluno menor. Se o app for usado diretamente por alunos menores, deve ir para a Kids Category com restrições adicionais.

---

## Guideline 2 — Performance

### 2.1 — App Completeness
| Item | Status | Observação |
|------|--------|------------|
| App é funcional e completo (sem placeholders) | ⚠️ | Revisar telas com conteúdo "Em breve" |
| Todas as funcionalidades declaradas na descrição funcionam | ⚠️ | Alinhar com copy do App Store antes de submeter |
| App não trava ou fecha inesperadamente | 🔲 | Executar testes de regressão |
| App carrega sem erros em dispositivo limpo | 🔲 | Testar em TestFlight antes de submeter |

### 2.3 — Accurate Metadata
| Item | Status | Observação |
|------|--------|------------|
| Nome do app não inclui palavras proibidas (grátis, #1, melhor) | ✅ | "Lexend Scholar" — OK |
| Screenshots mostram funcionalidades reais do app | ⚠️ | Aguardando produção dos screenshots (LS-90) |
| Descrição não menciona outras plataformas (Android, etc.) | ✅ | |
| Palavras-chave não repetem o nome do app | ✅ | Ver LS-90/aso-keywords.md |

### 2.4 — Hardware Compatibility
| Item | Status | Observação |
|------|--------|------------|
| App funciona em todos os dispositivos declarados (iPhone + iPad) | ⚠️ | Testar no iPad em orientação landscape |
| App suporta iOS 18+ conforme declarado | ✅ | `deploymentTarget: "18.0"` no project.yml |

---

## Guideline 3 — Business

### 3.1 — Payments
| Item | Status | Observação |
|------|--------|------------|
| Se houver compras in-app, usam sistema de IAP da Apple | ✅ | App B2B (escola paga via web); sem IAP no app iOS |
| App não direciona usuários a comprar fora da App Store | ✅ | Assinatura é gerenciada via painel web |

### 3.2 — Other Business Model Issues
| Item | Status | Observação |
|------|--------|------------|
| App não é apenas um wrapper de site (thin app) | ✅ | App nativo SwiftUI |
| App oferece valor real ao usuário iOS | ✅ | |

---

## Guideline 4 — Design

### 4.0 — Design
| Item | Status | Observação |
|------|--------|------------|
| Interface segue Human Interface Guidelines | ✅ | SwiftUI nativo |
| App usa componentes nativos iOS (não simula Android/Material) | ✅ | |
| App não replica funcionalidades nativas sem valor adicional | ✅ | |

### 4.2 — Minimum Functionality
| Item | Status | Observação |
|------|--------|------------|
| App tem funcionalidade além de website/PDF | ✅ | Push notifications, dados offline, câmera |
| App não é apenas um conjunto de links | ✅ | |

---

## Guideline 5 — Legal

### 5.1 — Privacy
| Item | Status | Observação |
|------|--------|------------|
| App tem Política de Privacidade acessível | ⚠️ | URL da Privacy Policy deve ser adicionada no App Store Connect |
| Privacy Policy cobre todos os dados coletados | ⚠️ | Aguardando finalização do documento legal |
| App pede permissão antes de acessar dados sensíveis (câmera, foto, etc.) | ✅ | SwiftUI pede permissão automaticamente |
| NSUsageDescription preenchido para cada permissão solicitada | ⚠️ | Verificar Info.plist gerado pelo XcodeGen para: câmera, galeria, notificações |

### 5.1.1 — Data Collection and Storage
| Item | Status | Observação |
|------|--------|------------|
| Privacy Nutrition Labels declarados corretamente | ⚠️ | Em progresso — ver docs/store/privacy-nutrition-labels.md (LS-91) |
| Dados coletados limitados ao necessário (data minimization) | ✅ | Sem SDKs de analytics third-party invasivos |
| Dados transmitidos via HTTPS/TLS | ✅ | Supabase usa TLS 1.3 |
| Dados armazenados localmente protegidos (Keychain, Data Protection) | ⚠️ | Verificar que tokens de autenticação usam Keychain, não UserDefaults |

### 5.1.2 — Data Use and Sharing
| Item | Status | Observação |
|------|--------|------------|
| Dados não compartilhados com terceiros sem consentimento | ✅ | Apenas Supabase (processador de dados) |
| Sem SDKs de publicidade ou data brokers | ✅ | |
| Device token APNs não compartilhado com terceiros | ✅ | Apenas Supabase para push |

### 5.1.3 — Health and Health Research
| Item | Status | Observação |
|------|--------|------------|
| App não coleta dados de saúde sem justificativa | ✅ | Não aplicável |

### 5.1.4 — Kids and Minors
| Item | Status | Observação |
|------|--------|------------|
| App não coleta dados de identificação de menores sem consentimento parental | ⚠️ | **CRÍTICO** — Verificar com Legal: alunos menores têm dados cadastrados pelos gestores (adultos), não por eles mesmos |
| App não exige conta de menor para funcionar | ✅ | Acesso feito por gestores/professores |
| Sem publicidade comportamental para menores | ✅ | |

### 5.5 — Developer Code of Conduct
| Item | Status | Observação |
|------|--------|------------|
| App não facilita atividades ilegais | ✅ | |
| App não viola privacidade de usuários | ✅ | |

---

## Guideline Especial — Apps Educacionais com Dados de Menores

### Requisitos FERPA / LGPD para apps de gestão escolar

| Requisito | Status | Ação necessária |
|-----------|--------|-----------------|
| Consentimento dos responsáveis para coleta de dados do aluno | ⚠️ | Incluir cláusula no contrato escola–família e no Termo de Uso do app |
| Dados educacionais usados apenas para fins educacionais | ✅ | Não há monetização via dados |
| Direito de acesso e exclusão para responsáveis legais | ⚠️ | Implementar fluxo de solicitação de exclusão de conta no app ou via suporte |
| Breach notification (notificar vazamento em até 72h — LGPD Art. 48) | ⚠️ | Definir procedimento de incident response com time de segurança |
| Dados não transferidos para jurisdição com proteção inadequada | ✅ | Supabase hospedado no Brasil (sa-east-1) — verificar |

---

## Plano de Ação — Itens Não Conformes

### Prioridade Alta (bloqueia submissão)

1. **Privacy Policy URL** — Criar e hospedar política de privacidade pública. Adicionar URL no App Store Connect antes de submeter.
   - Responsável: Time Legal
   - Prazo: antes da submissão

2. **Privacy Nutrition Labels** — Preencher no App Store Connect conforme `privacy-nutrition-labels.md`.
   - Responsável: Agente App Store (LS-91)
   - Prazo: antes da submissão

3. **Dados de menores — consentimento** — Adicionar tela de aceite de Termos de Uso no onboarding (consentimento do gestor/responsável adulto).
   - Responsável: Time iOS + Legal
   - Prazo: antes da submissão

### Prioridade Média (recomendado antes de submeter)

4. **NSUsageDescription** — Verificar strings de permissão no Info.plist gerado. Adicionar no `project.yml` se necessário.
5. **Keychain para tokens** — Confirmar que `SupabaseService.swift` usa Keychain para armazenar access_token.
6. **Testes em TestFlight** — Distribuir beta para testes antes de submeter para revisão.

### Prioridade Baixa (pós-lançamento)

7. **Fluxo de exclusão de conta** — Desde junho 2023, Apple exige fluxo de exclusão de conta no app (Guideline 5.1.1).
8. **Confirmação de hosting Supabase no Brasil** — Verificar region do projeto Supabase para conformidade com LGPD.

---

## Referências

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple — Privacy Best Practices](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy)
- [Account Deletion Requirement](https://developer.apple.com/news/releases/2022-10-24-new-review-guidelines/)
- [LGPD — Lei 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/L13709.htm)
- [FERPA (se distribuído nos EUA)](https://www2.ed.gov/policy/gen/guid/fpco/ferpa/index.html)
