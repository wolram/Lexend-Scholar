# Wiki de Engenharia — Lexend Scholar

**Mantido por**: Time de Engenharia
**Última atualização**: Abril 2026

---

## Bem-vindo ao Wiki do Lexend Scholar

Este wiki é a fonte de verdade técnica do Lexend Scholar. Aqui você encontra tudo que precisa para entender, desenvolver, operar e manter o sistema.

**Regra de ouro**: Se você teve que descobrir algo que não estava documentado, documente após descobrir. O wiki só fica bom se todos contribuem.

---

## Estrutura do Wiki

### Arquitetura e Design
- [Visão Geral da Arquitetura](arquitetura.md) — Stack, componentes, decisões de design
- [ADRs — Architecture Decision Records](adrs/) — Registro de decisões técnicas importantes
- [Modelo de Dados](modelo-dados.md) — Esquema do banco de dados, relações, índices
- [Fluxo de Dados](fluxo-dados.md) — Como dados fluem entre frontend, backend e banco

### APIs e Integrações
- [API Reference](api-reference.md) — Endpoints, autenticação, exemplos
- [Integrações Externas](integracoes/) — Stripe, NFE.io, Crisp, Supabase
- [Webhooks](webhooks.md) — Eventos enviados e recebidos

### iOS
- [Onboarding iOS — Setup do Ambiente](ios-onboarding.md) — Primeiro acesso para devs iOS
- [Arquitetura iOS](ios-arquitetura.md) — MVVM, SwiftUI, dados, navegação
- [Design System iOS](ios-design-system.md) — SchoolPalette, componentes, tipografia
- [Testes iOS](ios-testes.md) — XCTest, UI Tests, mocking

### Banco de Dados
- [Schema do Banco](banco-schema.md) — Tabelas, colunas, tipos, constraints
- [Migrações](banco-migracoes.md) — Como criar e aplicar migrações no Supabase
- [Row Level Security (RLS)](banco-rls.md) — Políticas de segurança por row
- [Performance e Índices](banco-performance.md) — Queries lentas, índices recomendados

### CI/CD e Deploy
- [Pipeline de CI/CD](cicd.md) — GitHub Actions, testes automáticos, deploy
- [Ambientes](ambientes.md) — Local, Staging, Produção — URLs e configurações
- [Deploy Web](deploy-web.md) — Deploy no Vercel, variáveis de ambiente
- [Deploy iOS](deploy-ios.md) — Xcode Archive, App Store Connect, TestFlight

### Segurança
- [Modelo de Segurança](seguranca.md) — Autenticação, autorização, criptografia
- [Gestão de Secrets](secrets.md) — Como gerenciar e rotar secrets
- [LGPD e Privacidade](lgpd-tech.md) — Implementação técnica dos requisitos de privacidade

### Operações
- [Monitoramento](monitoramento.md) — Sentry, Better Uptime, alertas
- [Logs](logs.md) — Estrutura de logs, como buscar, retenção
- [Runbooks](runbooks/) — Procedimentos para situações específicas de operação

### Onboarding de Engenheiro
- [Onboarding Geral](onboarding-eng.md) — Primeiro dia, acessos, ferramentas
- [Onboarding iOS](ios-onboarding.md) — Setup específico para desenvolvedores iOS
- [Onboarding Backend](backend-onboarding.md) — Setup para desenvolvedores backend/fullstack
- [Convenções de Código](convencoes.md) — Style guide, naming, padrões

### Troubleshooting
- [Problemas Comuns](troubleshooting.md) — Erros frequentes e soluções
- [Debug iOS](debug-ios.md) — Ferramentas e técnicas de debugging no iOS
- [Debug Backend](debug-backend.md) — Logs, queries, debugging da API

---

## Links Rápidos

| Recurso | URL |
|---|---|
| App em Produção | app.lexendscholar.com |
| App em Staging | staging.lexendscholar.com |
| Supabase (Produção) | app.supabase.com/project/[ID] |
| Vercel Dashboard | vercel.com/lexend-scholar |
| Sentry | sentry.io/organizations/lexend-scholar |
| Linear | linear.app/lexend-scholar |
| Figma | figma.com/files/[ID] |
| App Store Connect | appstoreconnect.apple.com |
| GitHub | github.com/lexend-scholar/app |

---

## Convenções Gerais

### Git
- **Branch principal**: `main`
- **Feature branches**: `feature/LS-XXX-descricao-curta`
- **Hotfix branches**: `hotfix/descricao-curta`
- **Commits**: Conventional Commits — `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`

### Issues no Linear
- Todo trabalho deve ter uma issue no Linear antes de começar
- PR deve referenciar a issue: "Closes LS-XXX"
- Label e estimativa obrigatórios antes de mover para In Progress

### Code Review
- Mínimo 1 aprovação antes do merge (2 para mudanças críticas)
- PR deve passar em todos os checks do CI
- Reviewer deve ser diferente do autor

---

## Como Contribuir com o Wiki

1. Qualquer engenheiro pode e deve contribuir
2. Para mudanças pequenas (correções, adições): commit direto em main
3. Para novos documentos ou reestruturação: PR com revisão
4. Manter documentos atualizados quando o código muda
5. Usar Markdown padrão — sem HTML inline
6. Adicionar ao índice quando criar novo documento

---

## Atualização e Manutenção

- **Owner**: Engineering Lead (Marlow Sousa)
- **Revisão completa**: Trimestral
- **Documentos desatualizados**: Marcados com `[DESATUALIZADO]` no título
- **Documentos em rascunho**: Marcados com `[RASCUNHO]` no título
