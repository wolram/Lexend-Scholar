# Checklist de Validação Manual Pré-Release

> Issue: LS-171 | Criar checklist de validação manual pré-release
> Versão: _____ | Data: _____ | QA Responsável: _____

---

## Bloco 1 — Autenticação

- [ ] **1.1** Login como administrador funciona com credenciais válidas
- [ ] **1.2** Login como professor funciona com credenciais válidas
- [ ] **1.3** Login como responsável/pai funciona com credenciais válidas
- [ ] **1.4** Logout encerra sessão corretamente e redireciona para tela de login
- [ ] **1.5** Reset de senha via email funciona (email recebido, link válido, senha redefinida com sucesso)
- [ ] **1.6** Sessão expirada redireciona para login sem perda de dados visível

---

## Bloco 2 — Cadastro de Alunos

- [ ] **2.1** Criar novo aluno com todos os campos obrigatórios preenchidos
- [ ] **2.2** Editar dados de aluno existente e salvar corretamente
- [ ] **2.3** Arquivar aluno (remover da lista ativa sem excluir o histórico)
- [ ] **2.4** Listar alunos com paginação funcionando corretamente
- [ ] **2.5** Buscar aluno por nome e por matrícula retorna resultados corretos
- [ ] **2.6** Importar planilha CSV com alunos (layout padrão) sem erros

---

## Bloco 3 — Frequência

- [ ] **3.1** Registrar frequência para turma completa (marcar presentes e ausentes)
- [ ] **3.2** Editar registro de frequência já salvo (corrigir ausência/presença)
- [ ] **3.3** Relatório diário de frequência exibe dados corretos
- [ ] **3.4** Relatório mensal de frequência exibe percentuais corretos por aluno
- [ ] **3.5** Notificação de falta enviada para responsável quando aluno é marcado ausente
- [ ] **3.6** Registro de frequência funciona em modo offline e sincroniza ao reconectar

---

## Bloco 4 — Notas e Boletim

- [ ] **4.1** Lançar nota para aluno em disciplina específica salva corretamente
- [ ] **4.2** Editar nota lançada anteriormente atualiza o valor e recalcula média
- [ ] **4.3** Média calculada automaticamente conforme critério configurado (aritmética/ponderada)
- [ ] **4.4** Gerar boletim em PDF com dados corretos (nome, turma, notas, médias)
- [ ] **4.5** Enviar boletim PDF para responsável via app (push + disponível para download)
- [ ] **4.6** Histórico de notas por aluno exibe períodos anteriores corretamente

---

## Bloco 5 — Financeiro

- [ ] **5.1** Gerar cobrança mensal para turma ou escola inteira sem erros
- [ ] **5.2** Registrar pagamento manual com data, valor e forma de pagamento
- [ ] **5.3** Relatório de inadimplência lista corretamente alunos com cobranças vencidas
- [ ] **5.4** Exportar relatório financeiro em formato XLSX com dados corretos
- [ ] **5.5** Fluxo de pagamento via Stripe Checkout funciona do início ao fim (sandbox)
- [ ] **5.6** Webhook de pagamento do Stripe atualiza status da cobrança automaticamente

---

## Bloco 6 — Comunicados

- [ ] **6.1** Criar comunicado com texto e (opcional) anexo
- [ ] **6.2** Enviar comunicado para turma específica
- [ ] **6.3** Enviar comunicado para escola inteira (todas as turmas)
- [ ] **6.4** Push notification iOS recebida pelo responsável ao receber comunicado
- [ ] **6.5** Push notification Android recebida pelo responsável ao receber comunicado
- [ ] **6.6** Confirmação de leitura registrada quando responsável abre o comunicado

---

## Bloco 7 — Performance

- [ ] **7.1** Cold start (primeira abertura) < 1.5s em iPhone SE (medir com Instruments)
- [ ] **7.2** Carregamento da lista de alunos (200+ alunos) < 1s após login
- [ ] **7.3** Geração de boletim em PDF < 3s para boletim com 10 disciplinas
- [ ] **7.4** Sem ANR (Application Not Responding) no Android durante uso normal
- [ ] **7.5** Scroll na lista de alunos a 60fps sem jank (verificar com Instruments/Perfetto)
- [ ] **7.6** Memória em uso idle < 200MB (verificar com Instruments → Allocations)

---

## Bloco 8 — Compatibilidade

- [ ] **8.1** Funcional no iPhone SE (2ª ou 3ª geração) — device mínimo suportado iOS
- [ ] **8.2** Funcional no iPhone 15 Pro — device máximo atual iOS
- [ ] **8.3** Funcional no iPad Air (5ª geração) com layout two-pane
- [ ] **8.4** Website funcional no Chrome 120+ (Windows e Mac)
- [ ] **8.5** Website funcional no Safari 17+ (Mac e iOS)
- [ ] **8.6** Website funcional no Firefox 120+ (Windows e Mac)

---

## Bloco 9 — Acessibilidade

- [ ] **9.1** Contraste de texto WCAG AA (≥4.5:1) em todas as telas principais
- [ ] **9.2** Elementos interativos com tamanho mínimo de toque de 44×44px
- [ ] **9.3** VoiceOver iOS lê corretamente os elementos principais (dashboard, lista, formulários)
- [ ] **9.4** TalkBack Android lê corretamente os elementos principais
- [ ] **9.5** Navegação por teclado no website (Tab order lógico, focus visible)
- [ ] **9.6** Fontes escaláveis respeitam a configuração de tamanho de fonte do sistema

---

## Bloco 10 — Segurança

- [ ] **10.1** Dados de alunos menores protegidos — acesso apenas com autenticação válida
- [ ] **10.2** Todas as chamadas de API usam HTTPS (sem mixed content)
- [ ] **10.3** Token expirado ou inválido redireciona para login imediatamente
- [ ] **10.4** Dados sensíveis (tokens, senhas) não aparecem em logs do app ou servidor
- [ ] **10.5** Website com CSP (Content Security Policy) configurada (verificar header `Content-Security-Policy`)
- [ ] **10.6** Rate limiting na API bloqueia mais de 100 requests/minuto por IP (testar com k6)

---

## Resultado Final

| Bloco | Total de Itens | Passou | Falhou | Bloqueadores |
|-------|---------------|--------|--------|-------------|
| 1 — Autenticação | 6 | | | |
| 2 — Cadastro de Alunos | 6 | | | |
| 3 — Frequência | 6 | | | |
| 4 — Notas e Boletim | 6 | | | |
| 5 — Financeiro | 6 | | | |
| 6 — Comunicados | 6 | | | |
| 7 — Performance | 6 | | | |
| 8 — Compatibilidade | 6 | | | |
| 9 — Acessibilidade | 6 | | | |
| 10 — Segurança | 6 | | | |
| **TOTAL** | **60** | | | |

### Decisão Go/No-Go

- [ ] **GO** — Todos os blocos aprovados, zero bloqueadores
- [ ] **NO-GO** — Um ou mais itens de bloqueio falharam

**Justificativa (se NO-GO):**

_______________________________________________

**Assinatura QA:** _________________ **Data:** _________________

**Assinatura Tech Lead:** _________________ **Data:** _________________
