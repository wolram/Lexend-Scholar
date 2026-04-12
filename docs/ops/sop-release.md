# SOP: Release iOS e Web — Lexend Scholar

**Versão**: 1.0
**Owner**: Engineering Lead
**Última atualização**: Abril 2026

---

## Visão Geral

Este SOP define o processo padrão de release para o app iOS e a plataforma web do Lexend Scholar. O objetivo é garantir qualidade, rastreabilidade e comunicação adequada a cada lançamento.

**Tipos de release:**
- **Patch (x.x.PATCH)**: Hotfix de bug crítico — pode ser feito a qualquer hora
- **Minor (x.MINOR.0)**: Nova feature ou melhoria — semanal (sextas-feiras)
- **Major (MAJOR.0.0)**: Quebra de compatibilidade significativa — planejado com antecedência

---

## Checklist de Release iOS

### Fase 1: Preparação (D-5 dias antes do release)

- [ ] **Branch de release criado**: `git checkout -b release/x.x.x`
- [ ] **CHANGELOG.md atualizado**: Listar todas as mudanças em linguagem para usuário final
- [ ] **Version bump feito**: Incrementar `CFBundleShortVersionString` e `CFBundleVersion` no `project.yml`
- [ ] **Testes automatizados passando**: `xcodebuild test` sem falhas
- [ ] **SwiftLint sem warnings**: `swiftlint lint` com zero warnings
- [ ] **Build de release compilando**: `xcodebuild archive` com sucesso

### Fase 2: Testes (D-3 dias)

- [ ] **Teste em simulador**: iPhone 15 Pro, iPhone SE (3rd gen), iPad Pro
- [ ] **Teste em device físico**: Ao menos 1 iPhone real
- [ ] **Teste do fluxo crítico de matrícula**: Criar aluno → atribuir turma → confirmar
- [ ] **Teste do fluxo de frequência**: Lançar, salvar, verificar offline, sincronizar
- [ ] **Teste de lançamento de notas**: Criar avaliação, lançar notas, verificar média
- [ ] **Teste do módulo financeiro**: Gerar cobrança, simular pagamento
- [ ] **Teste de notificações push**: Falta gera notificação no responsável
- [ ] **Teste de modo offline**: Desligar WiFi, registrar frequência, religar e verificar sync
- [ ] **Teste de acessibilidade**: VoiceOver funcional nas telas principais
- [ ] **Memory leaks**: Instruments com Leaks profiler — zero regressões

### Fase 3: Submissão para App Store (D-2 dias)

- [ ] **Archive criado**: Product → Archive no Xcode
- [ ] **Upload para App Store Connect**: Distribute App → App Store Connect
- [ ] **Release notes em PT-BR escritas**: Para o que é novo nesta versão
- [ ] **Release notes em EN (requerido pela Apple)**: Tradução básica das notas
- [ ] **Screenshots atualizados** (se houver mudança visual nas telas principais)
- [ ] **Configurar release como "Manual Release"** (não publicar automaticamente após aprovação)
- [ ] **Aguardar aprovação da Apple**: Normalmente 24-48h

### Fase 4: Release Day

- [ ] **Confirmação com co-fundadores**: Sinal verde para liberar
- [ ] **Publicar no App Store**: App Store Connect → Release this version
- [ ] **Verificar no App Store**: Buscar "Lexend Scholar" e confirmar versão nova
- [ ] **Atualizar Linear**: Mover todas as issues da versão para "Done"
- [ ] **Comunicar no Slack** `#releases`:
  ```
  App iOS v{versão} publicado na App Store!
  Novidades: {resumo das principais mudanças}
  Issues incluídas: LS-XXX, LS-XXX
  ```
- [ ] **Monitorar Crash Rate**: Crashlytics — primeiras 4 horas pós-release
- [ ] **Monitorar Sentry**: Primeiras 4 horas — zero aumento de errors
- [ ] **Monitorar reviews recentes** no App Store: Responder problemas rapidamente

### Fase 5: Pós-Release

- [ ] **Merge do branch de release para main**: `git merge release/x.x.x`
- [ ] **Tag criada**: `git tag -a v{versão} -m "Release v{versão}"`
- [ ] **Tag pushed**: `git push origin v{versão}`
- [ ] **Issue de acompanhamento criada no Linear**: Release hotfix se necessário
- [ ] **CHANGELOG.md commitado em main**

---

## Checklist de Release Web

### Fase 1: Preparação (D-3 dias)

- [ ] **Branch de release criado**: `git checkout -b release/web-x.x.x`
- [ ] **Build de produção sem erros**: `npm run build` com zero warnings críticos
- [ ] **Variáveis de ambiente de produção verificadas**: `.env.production` completo
- [ ] **Bundle size verificado**: Não regrediu mais que 10% vs release anterior
- [ ] **Testes e2e passando**: `playwright test` com zero falhas

### Fase 2: Staging Deploy (D-2 dias)

- [ ] **Deploy em staging**: `vercel --env staging` ou push para branch de staging
- [ ] **Smoke test manual em staging**:
  - [ ] Login funciona
  - [ ] Cadastrar aluno: OK
  - [ ] Lançar frequência: OK
  - [ ] Emitir declaração: PDF gerado
  - [ ] Financeiro: gerar cobrança
- [ ] **Performance testada**: Lighthouse score > 90 em todas as métricas
- [ ] **Mobile responsivo verificado**: Chrome DevTools Mobile View

### Fase 3: Produção Deploy

- [ ] **Horário do deploy**: Preferencialmente 22h-02h BRT (menor tráfego)
- [ ] **Comunicado de manutenção** (para deploys > 5 min): Banner no sistema
- [ ] **Deploy realizado**: `vercel --prod` ou merge para branch main com CI/CD
- [ ] **Verificar URL de produção**: app.lexendscholar.com respondendo
- [ ] **Verificar health check**: GET /api/health retorna 200
- [ ] **Verificar login**: Teste de login com conta de teste
- [ ] **Rollback preparado**: Vercel permite rollback instantâneo

### Fase 4: Pós-Release Web

- [ ] **Monitorar Sentry**: 30 minutos pós-deploy
- [ ] **Monitorar Vercel Analytics**: Verificar taxa de erro
- [ ] **Comunicar no Slack** `#releases`

---

## Processo de Hotfix (Urgência)

Para bugs críticos (P0) que exigem release fora do ciclo normal:

1. **Criar branch hotfix**: `git checkout -b hotfix/descricao-do-bug main`
2. **Implementar fix com testes**
3. **Review obrigatório de um segundo dev** (mesmo para times pequenos)
4. **Checklist de release resumido**: Apenas itens críticos de qualidade
5. **iOS**: Submeter como hotfix — App Store costuma aprovar em < 24h para hotfixes
6. **Web**: Deploy imediato após aprovação do review
7. **Postmortem**: Criar documento em `docs/ops/postmortems/` em até 48h

---

## Rollback

### iOS
- Não é possível fazer rollback de versões no App Store para usuários que já atualizaram
- Mantenha a versão anterior arquivada no Xcode
- Em casos extremos: Submeter nova versão como hotfix urgente

### Web
- Rollback instantâneo via Vercel: `vercel rollback`
- Ou via GitHub: reverter o commit de deploy e fazer push

---

## Contatos de Escalação para Releases

| Situação | Contato |
|---|---|
| Apple Review rejeitado | Founder (decisão de resubmissão) |
| Crash rate > 1% pós-release | Engineering Lead + Founder |
| Rollback necessário | Engineering Lead (autoriza) + Founder (notificado) |
| Release com impacto em clientes Enterprise | Avisar CSM antes do release |
