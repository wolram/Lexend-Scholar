# LS-171 — Checklist de Validação Manual Pré-Release

## Instruções de Uso

Este checklist deve ser executado pelo QA Lead antes de cada release.
**Nenhum deploy para produção pode ocorrer com itens bloqueantes não marcados.**

- Preencher a data de execução e o nome do executante
- Para cada item: marcar ✅ (passou), ❌ (falhou), ⚠️ (passou com ressalvas)
- Falhas em itens bloqueantes impedem o release — abrir bug no Linear imediatamente
- Ressalvas devem ser documentadas no campo de observações

---

## Cabeçalho do Checklist

| Campo | Valor |
|-------|-------|
| Versão | ___.___.___ |
| Data de execução | ___/___/______ |
| Executado por | _______________________ |
| Ambiente | Staging / Produção |
| Dispositivo iOS | iPhone ___ (iOS ___) |
| Dispositivo Android | _______________ (Android ___) |
| Browser Web | Chrome ___ / Safari ___ |

---

## BLOCO 1 — Autenticação (por perfil)

### 1.1 Perfil Diretor

| # | Ação | Resultado Esperado | Bloqueante | Status | Obs |
|---|------|--------------------|-----------|--------|-----|
| 1 | Abrir app / acessar site | Tela de login exibida | Sim | | |
| 2 | Login com credenciais de diretor | Entrar no dashboard de direção | Sim | | |
| 3 | Verificar permissões: ver relatórios gerais | Relatórios disponíveis | Sim | | |
| 4 | Verificar permissões: configurações da escola | Menu de configurações visível | Sim | | |
| 5 | Logout | Retornar à tela de login, sessão encerrada | Sim | | |

### 1.2 Perfil Secretária

| # | Ação | Resultado Esperado | Bloqueante | Status | Obs |
|---|------|--------------------|-----------|--------|-----|
| 6 | Login com credenciais de secretária | Entrar no painel de secretaria | Sim | | |
| 7 | Verificar que relatórios financeiros detalhados estão visíveis | Relatórios de cobrança acessíveis | Sim | | |
| 8 | Verificar que configurações avançadas estão ocultas | Menu de configurações não visível | Sim | | |
| 9 | Logout | Sessão encerrada corretamente | Sim | | |

### 1.3 Perfil Professor

| # | Ação | Resultado Esperado | Bloqueante | Status | Obs |
|---|------|--------------------|-----------|--------|-----|
| 10 | Login com credenciais de professor | Entrar no painel do professor | Sim | | |
| 11 | Verificar que apenas suas turmas são visíveis | Não ver turmas de outros professores | Sim | | |
| 12 | Verificar que dados financeiros estão ocultos | Sem acesso ao módulo financeiro | Sim | | |
| 13 | Sessão expirar após inatividade | Redirect para login após timeout | Não | | |

---

## BLOCO 2 — Cadastro de Aluno

| # | Ação | Resultado Esperado | Bloqueante | Status | Obs |
|---|------|--------------------|-----------|--------|-----|
| 14 | Clicar em "Novo Aluno" | Formulário de cadastro aberto | Sim | | |
| 15 | Preencher todos os campos obrigatórios | Campos validados em tempo real | Sim | | |
| 16 | Tentar salvar sem campo obrigatório | Mensagem de erro clara, sem crash | Sim | | |
| 17 | Salvar aluno com dados completos | Aluno aparece na lista imediatamente | Sim | | |
| 18 | Editar dados do aluno cadastrado | Alterações salvas corretamente | Sim | | |
| 19 | Buscar aluno por nome | Resultado correto retornado | Não | | |
| 20 | Inativar aluno (não excluir) | Aluno não aparece em listas ativas | Sim | | |

---

## BLOCO 3 — Controle de Frequência

| # | Ação | Resultado Esperado | Bloqueante | Status | Obs |
|---|------|--------------------|-----------|--------|-----|
| 21 | Selecionar turma para chamada | Lista de alunos da turma carregada | Sim | | |
| 22 | Marcar aluno como presente | Status atualizado visualmente | Sim | | |
| 23 | Marcar aluno como ausente | Status atualizado visualmente | Sim | | |
| 24 | Alternar entre presente/ausente | Mudança refletida corretamente | Sim | | |
| 25 | Encerrar chamada | Chamada salva, resumo exibido | Sim | | |
| 26 | Verificar chamada salva no histórico | Chamada visível no histórico da turma | Sim | | |
| 27 | Tentar editar chamada já encerrada (se permitido) | Comportamento esperado (edição ou bloqueio) | Não | | |

---

## BLOCO 4 — Lançamento de Notas

| # | Ação | Resultado Esperado | Bloqueante | Status | Obs |
|---|------|--------------------|-----------|--------|-----|
| 28 | Selecionar turma e bimestre | Grade de notas carregada | Sim | | |
| 29 | Lançar nota para aluno | Nota salva automaticamente ou via botão | Sim | | |
| 30 | Inserir nota fora do range (ex: 11 em escala 0-10) | Erro de validação exibido | Sim | | |
| 31 | Verificar cálculo de média | Média calculada corretamente | Sim | | |
| 32 | Identificar alunos em recuperação | Alunos com média < corte destacados | Sim | | |

---

## BLOCO 5 — Geração de Boletim

| # | Ação | Resultado Esperado | Bloqueante | Status | Obs |
|---|------|--------------------|-----------|--------|-----|
| 33 | Selecionar aluno e período | Dados do período carregados | Sim | | |
| 34 | Clicar em "Gerar Boletim" | PDF gerado em < 5 segundos | Sim | | |
| 35 | Verificar conteúdo do PDF | Notas, médias e conceitos corretos | Sim | | |
| 36 | Compartilhar boletim via WhatsApp | Share sheet aberta com PDF anexado | Não | | |
| 37 | Compartilhar boletim via e-mail | E-mail composto com PDF em anexo | Não | | |

---

## BLOCO 6 — Módulo Financeiro

| # | Ação | Resultado Esperado | Bloqueante | Status | Obs |
|---|------|--------------------|-----------|--------|-----|
| 38 | Visualizar lista de mensalidades | Lista de cobranças carregada | Sim | | |
| 39 | Registrar pagamento manualmente | Status atualizado para "Pago" | Sim | | |
| 40 | Verificar relatório de inadimplência | Alunos inadimplentes listados | Sim | | |
| 41 | Enviar cobrança individual | Cobrança enviada (WhatsApp/e-mail) | Não | | |

---

## BLOCO 7 — Notificações e Comunicados

| # | Ação | Resultado Esperado | Bloqueante | Status | Obs |
|---|------|--------------------|-----------|--------|-----|
| 42 | Criar novo comunicado | Formulário aberto, campos obrigatórios presentes | Não | | |
| 43 | Publicar comunicado | Comunicado visível para destinatários | Não | | |
| 44 | Verificar notificação push recebida | Push exibida no dispositivo do responsável | Não | | |

---

## BLOCO 8 — Regressão de Performance

| # | Verificação | Critério | Bloqueante | Status | Obs |
|---|-------------|---------|-----------|--------|-----|
| 45 | Cold start do app iOS | ≤ 2,0 segundos (cronometrar manualmente) | Sim | | |
| 46 | Carregamento da lista de alunos (100 alunos) | ≤ 1 segundo visível | Não | | |
| 47 | Geração de boletim | ≤ 5 segundos | Sim | | |
| 48 | Carregamento de página web (home) | ≤ 3 segundos em 4G simulado | Não | | |

---

## BLOCO 9 — Compatibilidade

| # | Dispositivo / Ambiente | Teste | Status |
|---|----------------------|-------|--------|
| 49 | iPhone 15 Pro Max (iOS 18) | Login + frequência + boletim | |
| 50 | iPhone SE 2ª Gen (iOS 16, tela pequena) | UI adaptada corretamente | |
| 51 | iPad Pro 12.9" (iPadOS 18) | Layout em dois painéis | |
| 52 | Android (Samsung Galaxy, Android 13) | Login + frequência + boletim | |
| 53 | Android (entrada, Android 8.0) | Funcional sem crash | |
| 54 | Chrome 120+ (desktop) | Website completo funcional | |
| 55 | Safari 17+ (macOS) | Website completo funcional | |
| 56 | Chrome Mobile (Android) | Website responsivo | |

---

## BLOCO 10 — Segurança (Rápida)

| # | Verificação | Critério | Bloqueante | Status |
|---|-------------|---------|-----------|--------|
| 57 | Acesso sem token de autenticação | Redirect para login, sem dados expostos | Sim | |
| 58 | Tentar acessar dados de outra escola (via URL) | Acesso negado (403) | Sim | |
| 59 | Campo de texto: injeção simples `<script>` | Script não executado | Sim | |
| 60 | HTTPS obrigatório no website | Redirect HTTP → HTTPS automático | Sim | |

---

## Resultado Final

| Gate | Total Itens | Passou | Falhou | Status |
|------|-------------|--------|--------|--------|
| Autenticação | 13 | | | |
| Cadastro de Aluno | 7 | | | |
| Frequência | 7 | | | |
| Notas | 5 | | | |
| Boletim | 5 | | | |
| Financeiro | 4 | | | |
| Comunicados | 3 | | | |
| Performance | 4 | | | |
| Compatibilidade | 8 | | | |
| Segurança | 4 | | | |
| **TOTAL** | **60** | | | |

### Decisão de Release

- [ ] **Aprovado para release** — todos os itens bloqueantes passaram
- [ ] **Reprovado** — itens bloqueantes com falha (listar abaixo)

**Itens bloqueantes com falha:**
1. 
2. 

**Assinatura QA Lead:** _____________________ Data: ___/___/______

---

## Referências

- [Release Criteria — LS-166](./LS-166-release-criteria.md)
- [Baseline Performance iOS — LS-158](./LS-158-baseline-performance-ios.md)
- [Lighthouse — LS-160](./LS-160-lighthouse-audit.md)
