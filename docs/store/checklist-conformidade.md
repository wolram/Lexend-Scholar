# Checklist de Conformidade App Store — Lexend Scholar

> **Ref:** LS-99 | Atualizado: 2026-04-12
> **Objetivo:** Garantir que o app atenda a todos os requisitos da Apple App Store antes de cada submissão.

---

## 1. Metadata

| Item | Status | Resolve em | Observação |
|------|--------|-----------|------------|
| Título do app (máx. 30 caracteres) | ✅ | — | "Lexend Scholar" |
| Subtítulo (máx. 30 caracteres) | ✅ | — | "Gestão Escolar Inteligente" |
| Descrição curta (máx. 170 caracteres para preview) | ✅ | — | Aprovada |
| Descrição longa (máx. 4.000 caracteres) | ✅ | — | PT-BR e EN-US |
| Palavras-chave (máx. 100 caracteres, separadas por vírgula) | ✅ | — | gestão escolar, notas, frequência, alunos |
| URL de suporte | ✅ | — | https://suporte.lexendscholar.com.br |
| URL de privacidade | ✅ | — | https://lexendscholar.com.br/privacidade |
| URL de marketing (opcional) | ❌ | Sprint +1 | Criar landing page dedicada |
| Copyright (ex.: "© 2026 Lexend Tecnologia Ltda.") | ✅ | — | Configurado no App Store Connect |
| Categoria primária | ✅ | — | Education |
| Categoria secundária | ❌ | Sprint +1 | Definir: Business ou Productivity |

---

## 2. Screenshots e Mídia

| Tamanho / Dispositivo | Status | Resolve em | Observação |
|-----------------------|--------|-----------|------------|
| iPhone 6.9" (iPhone 16 Pro Max) — obrigatório | ❌ | Sprint +2 | Gerar no Simulator |
| iPhone 6.7" (iPhone 14 Plus) | ❌ | Sprint +2 | Gerar no Simulator |
| iPhone 6.5" (iPhone 11 Pro Max) | ❌ | Sprint +2 | Gerar no Simulator |
| iPhone 5.5" (iPhone 8 Plus) | ❌ | Sprint +2 | Gerar no Simulator |
| iPad 13" (iPad Pro M4) — obrigatório se Universal | ❌ | Sprint +2 | Gerar no Simulator |
| iPad 12.9" (iPad Pro 3ª geração) | ❌ | Sprint +2 | Gerar no Simulator |
| Mínimo de 3 screenshots por tamanho | ❌ | Sprint +2 | 3–10 por localização |
| Localização PT-BR | ❌ | Sprint +2 | Screenshots em português |
| Localização EN-US (se app multilíngue) | ❌ | Sprint +3 | Traduzir textos nos mockups |
| Vídeo de preview (máx. 30s, opcional mas recomendado) | ❌ | Sprint +3 | Roteiro a definir |

---

## 3. Privacy Nutrition Labels (App Privacy)

| Categoria de dado | Coletado? | Vinculado ao usuário? | Rastreamento? | Status | Resolve em |
|---|---|---|---|---|---|
| Nome | Sim | Sim | Não | ✅ | — |
| E-mail | Sim | Sim | Não | ✅ | — |
| Dados de uso (analytics) | Sim | Não | Não | ✅ | — |
| Diagnósticos (crash reports) | Sim | Não | Não | ✅ | — |
| Identificadores de dispositivo | Não | — | — | ✅ | — |
| Dados de saúde | Não | — | — | ✅ | — |
| Localização precisa | Não | — | — | ✅ | — |
| Dados de crianças (COPPA / Art. 14 LGPD) | Sim* | Controlado pela escola | Não | ❌ | Sprint +1 |
| Informações financeiras (Stripe) | Sim | Sim | Não | ✅ | — |

> *Dados de alunos menores de 18 anos são tratados sob responsabilidade da escola (controladora). Lexend Scholar é operadora. Ver DPA (LS-102).

**Ações pendentes:**
- [ ] Revisar declaração de "dados de crianças" no App Store Connect para refletir papel de operador (Sprint +1, estimativa: 2h)
- [ ] Adicionar categoria secundária no metadata (Sprint +1, estimativa: 1h)

---

## 4. Age Rating

| Item | Status | Resolve em | Observação |
|------|--------|-----------|------------|
| Age Rating definido como 4+ | ✅ | — | Sem conteúdo gerado por usuário público |
| Questionário de rating preenchido no App Store Connect | ✅ | — | Sem violência, sem conteúdo adulto |
| Conteúdo gerado por usuário (fóruns, chat público) | ✅ Ausente | — | Mensagens internas apenas entre escola e responsável |
| Sem referências a substâncias ou jogos de azar | ✅ | — | — |

---

## 5. In-App Purchases (IAP)

| Item | Status | Resolve em | Observação |
|------|--------|-----------|------------|
| Produtos IAP criados no App Store Connect | ❌ | Sprint +2 | Planos: Starter, Pro, Enterprise |
| Tipo: Auto-Renewable Subscription | ❌ | Sprint +2 | Mensal e anual |
| Descrição de cada plano em PT-BR e EN-US | ❌ | Sprint +2 | Redigir copy |
| Preço localizado (BRL) definido | ❌ | Sprint +2 | Alinhar com time de pricing |
| Restore purchases implementado no app | ❌ | Sprint +2 | Obrigatório pela Apple |
| Managed by Stripe (web) vs. StoreKit (iOS) — decisão documentada | ❌ | Sprint +1 | Definir arquitetura de billing (1 dia) |
| Família de assinaturas configurada | ❌ | Sprint +3 | Necessário para upgrade/downgrade |

---

## 6. TestFlight

| Item | Status | Resolve em | Observação |
|------|--------|-----------|------------|
| Grupo interno criado | ✅ | — | Time Lexend |
| Build enviada para TestFlight | ❌ | Sprint +2 | Aguarda CI/CD configurado |
| Grupo externo beta (até 10.000 usuários) | ❌ | Sprint +3 | Selecionar escolas parceiras |
| Beta App Review aprovado (grupo externo) | ❌ | Sprint +3 | Submeter após grupo interno ok |
| Notas de versão (What to Test) em PT-BR | ❌ | Sprint +2 | Redigir por build |
| Feedback de testadores revisado | ❌ | Sprint +3 | Processo a definir |
| Crash-free rate >= 99% antes da submissão | ❌ | Sprint +3 | Monitorar via Crashlytics/Xcode Organizer |

---

## 7. Revisão de Diretrizes Apple (Pre-Submission)

| Diretriz | Status | Resolve em |
|----------|--------|-----------|
| 1.1 — Conteúdo ofensivo | ✅ | — |
| 2.1 — Funcionalidade completa (sem placeholders) | ❌ | Sprint +2 |
| 2.3 — Metadata precisa (screenshots reais) | ❌ | Sprint +2 |
| 3.1.1 — IAP para bens digitais | ❌ | Sprint +2 |
| 4.0 — Design (Human Interface Guidelines) | ❌ | Sprint +2 |
| 5.1.1 — Coleta de dados com consentimento | ✅ | — |
| 5.1.2 — Compartilhamento de dados | ✅ | — |
| 5.1.4 — Dados de crianças | ❌ | Sprint +1 |

---

## Resumo de Pendências Críticas

| Sprint | Item | Esforço estimado |
|--------|------|-----------------|
| Sprint +1 | Revisar declaração dados de crianças no App Store Connect | 2h |
| Sprint +1 | Definir categoria secundária | 1h |
| Sprint +1 | Decisão arquitetura billing StoreKit vs Stripe | 1 dia |
| Sprint +2 | Screenshots todos os tamanhos (PT-BR) | 3 dias |
| Sprint +2 | IAP configurado no App Store Connect + Restore | 2 dias |
| Sprint +2 | Build no TestFlight (grupo interno) | 1 dia |
| Sprint +3 | Screenshots EN-US | 2 dias |
| Sprint +3 | TestFlight grupo externo + Beta Review | 3 dias |

---

*Documento vivo — atualizar a cada sprint. Responsável: Product Owner + Legal.*
