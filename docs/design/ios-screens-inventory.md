# Inventário de Telas iOS — Lexend Scholar

> Levantamento de todas as telas existentes em `app/Views/`.
> Última revisão: 2026-04-12.

## Status Legend

- Implementada — View SwiftUI funcional, conectada ao app shell
- Em progresso — View existe mas incompleta ou sem dados reais
- Nao implementada — Tela necessária mas sem arquivo Swift ainda

---

## Inventário Completo

### Autenticação (app/Views/Auth/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `LoginView.swift` | Tela de Login | Implementada | Alta | Entrada principal do app |
| `ProfileSelectionView.swift` | Seleção de Perfil | Implementada | Alta | Escolha entre Diretor/Prof/Responsável |

### Shell / Navegação (app/Views/Shell/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `AppShellView.swift` | Shell Principal | Implementada | Alta | NavigationSplitView, tab bar, menu lateral |

### Alunos (app/Views/Alunos/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `AlunosListView.swift` | Lista de Alunos | Implementada | Alta | Busca, filtros, lista paginada |
| `AlunoFormView.swift` | Formulário de Aluno | Implementada | Media | Criar/editar aluno, dados pessoais |
| — | Perfil do Aluno | Nao implementada | Alta | Detalhe com abas (acadêmico, financeiro, docs) |
| — | Histórico Acadêmico | Nao implementada | Media | Notas e frequência por período |

### Matrículas (app/Views/Matriculas/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `MatriculaFlowView.swift` | Fluxo de Matrícula | Implementada | Alta | Wizard 4 etapas (ver enrollment-flow.md) |
| — | Confirmação de Matrícula | Nao implementada | Alta | Tela de sucesso pós-matrícula |
| — | Lista de Matrículas | Nao implementada | Media | Gestão de matrículas do ano letivo |

### Turmas (app/Views/Turmas/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `TurmasListView.swift` | Lista de Turmas | Implementada | Alta | Cards de turma com alunos e professor |
| `TurmaFormView.swift` | Formulário de Turma | Implementada | Media | Criar/editar turma, série, turno |
| — | Detalhe da Turma | Nao implementada | Alta | Alunos matriculados, horário, professor |

### Professores (app/Views/Professores/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `ProfessoresListView.swift` | Lista de Professores | Implementada | Media | Lista com avatar, disciplinas |
| `ProfessorFormView.swift` | Formulário de Professor | Implementada | Media | Cadastro/edição de professor |
| — | Perfil do Professor | Nao implementada | Baixa | Turmas, histórico, documentos |

### Notas (app/Views/Notas/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `NotasLancamentoView.swift` | Lançamento de Notas | Implementada | Alta | Grid de alunos x avaliações |
| — | Histórico de Notas | Nao implementada | Media | Notas por bimestre/período |

### Frequência (app/Views/Frequencia/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `FrequenciaView.swift` | Controle de Frequência | Implementada | Alta | Chamada digital, lista de presença/falta |
| — | Relatório de Frequência | Nao implementada | Media | % por aluno, alertas de risco |

### Boletim (app/Views/Boletim/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `BoletimView.swift` | Boletim do Aluno | Implementada | Alta | Notas por disciplina, média, situação |
| — | Boletim Turma | Nao implementada | Media | Visão geral de desempenho da turma |

### Financeiro (app/Views/Financeiro/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `CobrancasView.swift` | Cobranças / Inadimplência | Implementada | Alta | Lista de cobranças com status |
| `MensalidadesConfigView.swift` | Configuração de Mensalidades | Implementada | Media | Valores, vencimentos, descontos |
| — | Detalhe de Cobrança | Nao implementada | Media | Histórico de pagamentos do aluno |
| — | Recibo Digital | Nao implementada | Media | Recibo de pagamento em PDF |

### Responsáveis (app/Views/Responsaveis/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `ResponsavelFormView.swift` | Formulário de Responsável | Implementada | Media | Dados do responsável, parentesco |
| — | Lista de Responsáveis | Nao implementada | Media | Gestão de responsáveis por aluno |

### Calendário (app/Views/Calendario/)

| Arquivo | Tela | Status | Prioridade Figma | Notas |
|---|---|---|---|---|
| `CalendarioLetivoView.swift` | Calendário Letivo | Implementada | Media | Eventos, feriados, datas de prova |
| — | Detalhe de Evento | Nao implementada | Baixa | Detalhes do evento, participantes |

### Telas Não Implementadas — Prioritárias

| Tela | Módulo | Prioridade | Justificativa |
|---|---|---|---|
| Dashboard / Home | — | Alta | Tela principal para diretores — KPIs do dia |
| Comunicados / Inbox | Comunicação | Alta | Módulo de mensagens escola-responsável |
| Envio de Comunicado | Comunicação | Alta | Composição e envio de comunicado |
| Perfil do Aluno (detail) | Alunos | Alta | Visão 360 do aluno |
| Declaração de Matrícula | Documentos | Alta | Emissão de documentos oficiais |
| Configurações do App | — | Media | Perfil de usuário, notificações, escola |
| Onboarding | — | Alta | Primeiros passos para escola nova |

---

## Resumo de Status

| Status | Quantidade |
|---|---|
| Implementada | 17 |
| Em progresso | 0 |
| Nao implementada | 14 |
| **Total identificado** | **31** |

---

## Prioridade para Finalizar no Figma

### Sprint 1 — Telas de alta prioridade de negócio
1. Dashboard / Home (diretor)
2. Perfil do Aluno (detalhe com abas)
3. Comunicados / Inbox
4. Envio de Comunicado
5. Confirmação de Matrícula (sucesso)

### Sprint 2 — Completar fluxos existentes
6. Detalhe da Turma
7. Histórico de Notas
8. Relatório de Frequência
9. Declaração de Matrícula (emissão)
10. Detalhe de Cobrança

### Sprint 3 — Completar cadastros e configurações
11. Lista de Responsáveis
12. Perfil do Professor
13. Boletim Turma
14. Configurações do App
15. Onboarding

---

## Dimensões para Figma

- **iPhone 15 Pro:** 393 × 852pt (principal)
- **iPhone SE 3:** 375 × 667pt (teste mínimo)
- **iPad Air 5:** 820 × 1180pt (opcional, NavigationSplitView)
