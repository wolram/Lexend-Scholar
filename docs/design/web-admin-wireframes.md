# Wireframes — Painel Administrativo Web

> Wireframes textuais do painel web do Lexend Scholar.
> Stack: Next.js + Tailwind CSS. Última revisão: 2026-04-12.

---

## Layout Base — Shell do Painel

```
┌─────────────────────────────────────────────────────────────────────┐
│ SIDEBAR (w-64, fixo)         │ MAIN CONTENT (flex-1)               │
│                              │                                       │
│ ┌──────────────────────────┐ │ ┌───────────────────────────────────┐│
│ │ 🎓 Lexend Scholar        │ │ │ Top Bar                           ││
│ └──────────────────────────┘ │ │  [Título da página]  [🔔][👤]    ││
│                              │ └───────────────────────────────────┘│
│ ── GESTÃO ─────────────────  │                                       │
│  📊 Dashboard                │  ┌─────────────────────────────────┐ │
│  👥 Alunos              ←    │  │  Conteúdo da página             │ │
│  🏫 Turmas                   │  │                                 │ │
│  👨‍🏫 Professores              │  │                                 │ │
│                              │  │                                 │ │
│ ── ACADÊMICO ───────────────  │  └─────────────────────────────────┘ │
│  📝 Notas                    │                                       │
│  📅 Frequência               │                                       │
│  📋 Boletins                 │                                       │
│  🗓 Calendário               │                                       │
│                              │                                       │
│ ── ADMINISTRATIVO ──────────  │                                       │
│  💰 Financeiro               │                                       │
│  📄 Documentos               │                                       │
│  📢 Comunicados              │                                       │
│  ⚙️  Configurações            │                                       │
│                              │                                       │
│ ──────────────────────────── │                                       │
│  [Avatar] Marlow Sousa       │                                       │
│  Administrador               │                                       │
└──────────────────────────────┴───────────────────────────────────────┘
```

---

## 1. Dashboard

```
┌── Top Bar ─────────────────────────────────────────────────────────┐
│  Dashboard                    Seg, 12 Abr 2026   [🔔 3] [👤 Ana]  │
└────────────────────────────────────────────────────────────────────┘

┌── Section Header ──────────────────────────────────────────────────┐
│  VISÃO GERAL                                                        │
│  Bom dia, Ana! Aqui está o resumo de hoje.                          │
│                              [Gerar Relatório ↓]                   │
└────────────────────────────────────────────────────────────────────┘

┌── Metric Cards (grid 4 colunas) ───────────────────────────────────┐
│                                                                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌───────────┐ │
│  │ 👥           │ │ ✅           │ │ 💰           │ │ ⚠️         │ │
│  │ Total Alunos │ │ Freq. Hoje   │ │ Inadimpl.    │ │ Alertas   │ │
│  │              │ │              │ │              │ │           │ │
│  │    342       │ │   87.3%      │ │   R$12.4k    │ │    8      │ │
│  │  +5% ↑ verde │ │  -2% ↓ verm │ │ +12% ↑ verm  │ │ Ver todos │ │
│  └──────────────┘ └──────────────┘ └──────────────┘ └───────────┘ │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘

┌── Gráfico de Frequência (últimos 30 dias) ─┐ ┌── Alertas ─────────┐
│                                            │ │                     │
│  100% ┤        .                           │ │ ⚠️ Lucas Silva       │
│   90% ┤  .  .    .  .  .  .               │ │    Freq: 68%         │
│   80% ┤         .          .  .           │ │                     │
│   70% ┤                         .         │ │ ⚠️ 5 alunos sem nota  │
│   60% ┤                                   │ │    Mat 6B - Bim.2    │
│       └────────────────────────────       │ │                     │
│        Set  Out  Nov  Dez  Jan  Fev  Mar  │ │ 💰 R$3.2k vencendo  │
│                                            │ │    amanhã (8 alunos) │
└────────────────────────────────────────────┘ └─────────────────────┘

┌── Turmas com Menor Frequência ─────────────────────────────────────┐
│                                                                     │
│  Turma          Professor        Freq. Mês    Status               │
│  ─────────────────────────────────────────────────────────         │
│  9A - Manhã     Carlos Motta     91.2%        ● Normal             │
│  6B - Tarde     Ana Lima         74.8%        ● Atenção            │
│  8C - Manhã     Pedro Santos     88.3%        ● Normal             │
│  7A - Tarde     Maria Costa      69.1%        ● Crítico            │
│                                                                     │
│                              [Ver todas as turmas →]               │
└────────────────────────────────────────────────────────────────────┘
```

---

## 2. Lista de Alunos

```
┌── Section Header ──────────────────────────────────────────────────┐
│  ALUNOS                                                             │
│  342 alunos matriculados                    [+ Novo Aluno]         │
└────────────────────────────────────────────────────────────────────┘

┌── Filtros ─────────────────────────────────────────────────────────┐
│  [🔍 Buscar por nome, RA ou responsável...]                         │
│                                                                     │
│  Turma: [Todas ▼]  Série: [Todas ▼]  Turno: [Todos ▼]             │
│  Status: [Ativo ▼]  Freq: [Todas ▼]  [Limpar filtros]             │
└────────────────────────────────────────────────────────────────────┘

┌── Tabela de Alunos ────────────────────────────────────────────────┐
│                                                                     │
│  ☐  Nome                  RA       Turma    Freq.   Status  Ações  │
│  ──────────────────────────────────────────────────────────────    │
│  ☐  [AB] Ana Beatriz S.   23001    9A       91%     ● Ativo  [⋯]  │
│  ☐  [LM] Lucas Martins    23045    6B       68%     ● Alerta [⋯]  │
│  ☐  [CP] Carla Pereira    23078    8C       95%     ● Ativo  [⋯]  │
│  ☐  [RS] Rafael Silva     23102    7A       100%    ● Ativo  [⋯]  │
│  ☐  [JO] Julia Oliveira   23134    9B       74%     ● Alerta [⋯]  │
│  ☐  [BN] Bruno Nascim.    22891    6A       45%     ● Crítico [⋯] │
│  ...                                                               │
│                                                                     │
│  [☐ Selec. todos]  Selecionados: 0   [Ação em lote ▼]             │
│                                                                     │
│  Exibindo 1-20 de 342   [< Anterior]  1 2 3 ... 18  [Próximo >]   │
└────────────────────────────────────────────────────────────────────┘
```

**Menu de ações [⋯]:**
- Ver perfil completo
- Editar dados
- Ver boletim
- Enviar mensagem ao responsável
- Emitir declaração
- Inativar matrícula

---

## 3. Perfil do Aluno

```
┌── Header do Aluno ─────────────────────────────────────────────────┐
│                                                                     │
│  [LM]  Lucas Martins                      [Editar] [Emitir Doc ▼] │
│  48pt  RA: 23045  |  Turma: 6B  |  Turno: Tarde                   │
│  azul  ● Ativo                                                      │
│                                                                     │
│  Freq. Atual: 68%  ⚠️ Abaixo do mínimo   Notas: 6.8 (média geral) │
└────────────────────────────────────────────────────────────────────┘

┌── Abas ────────────────────────────────────────────────────────────┐
│  [Dados Pessoais]  [Acadêmico]  [Financeiro]  [Comunicação]  [Docs]│
└────────────────────────────────────────────────────────────────────┘

┌── Aba: Dados Pessoais ─────────────────────────────────────────────┐
│                                                                     │
│  DADOS DO ALUNO                                                     │
│  Nome completo:   Lucas Martins Ferreira                           │
│  Data nascimento: 15/03/2011 (13 anos)                             │
│  CPF:             ***.***.***-42 (protegido LGPD)                  │
│  RG:              45.678.901-3                                      │
│  Endereço:        Rua das Flores, 123 – Jardim América, RP/SP      │
│                                                                     │
│  RESPONSÁVEL FINANCEIRO                                             │
│  Nome:    Roberto Henrique Alves                                   │
│  Relação: Pai                                                       │
│  Tel:     (16) 99999-1234                                           │
│  E-mail:  roberto@email.com                                         │
│                                                                     │
│  RESPONSÁVEL PEDAGÓGICO                                             │
│  Mesmo que o financeiro                                             │
└────────────────────────────────────────────────────────────────────┘

┌── Aba: Acadêmico ──────────────────────────────────────────────────┐
│                                                                     │
│  BOLETIM — 2º BIMESTRE 2026                [Ver histórico ↗]       │
│                                                                     │
│  Disciplina          Nota 1  Nota 2  Nota 3  Média  Situação       │
│  ──────────────────────────────────────────────────────────────    │
│  Matemática           7.0     6.5     —       6.75   ● Regular     │
│  Português            8.0     7.5     —       7.75   ● Aprovado    │
│  Ciências             5.0     6.0     —       5.50   ⚠️ Atenção     │
│  História             9.0     8.0     —       8.50   ● Aprovado    │
│  Geografia            6.0     5.5     —       5.75   ⚠️ Atenção     │
│                                                                     │
│  FREQUÊNCIA — Abril 2026                                           │
│  Aulas dadas: 22   Presenças: 15   Faltas: 7   Freq: 68.2% ⚠️     │
└────────────────────────────────────────────────────────────────────┘

┌── Aba: Financeiro ─────────────────────────────────────────────────┐
│                                                                     │
│  MENSALIDADES 2026                                                  │
│                                                                     │
│  Mês        Vencimento  Valor     Status           Ação            │
│  ──────────────────────────────────────────────────────────────    │
│  Fevereiro  10/02/2026  R$950,00  ● Pago            [Recibo]       │
│  Março      10/03/2026  R$950,00  ● Pago            [Recibo]       │
│  Abril      10/04/2026  R$950,00  ⚠️ Vencido         [Cobrar]       │
│  Maio       10/05/2026  R$950,00  ○ Aguardando      [Gerar Boleto] │
│                                                                     │
│  Saldo devedor: R$950,00   [Registrar Pagamento]  [Renegociar]    │
└────────────────────────────────────────────────────────────────────┘

┌── Aba: Comunicação ────────────────────────────────────────────────┐
│                                                                     │
│  [+ Nova Mensagem para Roberto]                                    │
│                                                                     │
│  ── 10 Abr 2026 ─────────────────────────────────────────         │
│  Escola  → Roberto: "Informamos que Lucas teve 3 faltas esta..."   │
│              Lido: 10/04 às 18:42  ✓✓                             │
│  Roberto → Escola: "Ok, ele estava doente. Enviarei atestado..."   │
│              Lido: 10/04 às 19:15  ✓✓                             │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

---

## 4. Emissão de Declarações

```
┌── Section Header ──────────────────────────────────────────────────┐
│  DOCUMENTOS                                                         │
│  Emissão de declarações e históricos escolares                      │
└────────────────────────────────────────────────────────────────────┘

┌── Formulário de Seleção ───────────────────────────────────────────┐
│                                                                     │
│  Passo 1 de 3: Selecionar Aluno e Documento                        │
│                                                                     │
│  Aluno:         [🔍 Buscar aluno por nome ou RA...]                │
│                                                                     │
│  Tipo de documento:                                                 │
│    ◉ Declaração de Matrícula                                        │
│    ○ Declaração de Frequência                                       │
│    ○ Histórico Escolar                                              │
│    ○ Declaração de Conclusão de Ano Letivo                          │
│    ○ Atestado de Escolaridade                                       │
│                                                                     │
│  Ano de referência: [2026 ▼]                                       │
│  Finalidade (opcional): [Ex.: Fins de cadastro em creche...]       │
│                                                                     │
│  Assinatura digital:   ◉ Diretora (Ana Cavalcanti)                 │
│                        ○ Secretaria                                 │
│                        ○ Coordenação Pedagógica                    │
│                                                                     │
│                                      [Cancelar]  [Visualizar →]    │
└────────────────────────────────────────────────────────────────────┘

┌── Pré-visualização do Documento ───────────────────────────────────┐
│                                                                     │
│  ┌────────────────────────────────────────────┐                    │
│  │          COLÉGIO HORIZONTE                  │  ← Preview PDF    │
│  │  CNPJ: 12.345.678/0001-90                  │     em painel     │
│  │  Ribeirão Preto - SP                       │     lateral ou    │
│  │                                            │     modal         │
│  │  DECLARAÇÃO DE MATRÍCULA                   │                    │
│  │                                            │                    │
│  │  Declaramos que LUCAS MARTINS FERREIRA,    │                    │
│  │  portador do CPF nº ***.***.***-42,        │                    │
│  │  está regularmente matriculado(a) nesta    │                    │
│  │  instituição de ensino no ano letivo de    │                    │
│  │  2026, cursando o 6º Ano do Ensino         │                    │
│  │  Fundamental, período Vespertino.          │                    │
│  │                                            │                    │
│  │  Ribeirão Preto, 12 de abril de 2026.     │                    │
│  │                                            │                    │
│  │  _____________________________             │                    │
│  │  Ana Beatriz Cavalcanti                   │                    │
│  │  Diretora                                  │                    │
│  │  CRE nº 12345/SP                           │                    │
│  └────────────────────────────────────────────┘                    │
│                                                                     │
│  [← Voltar]                    [Baixar PDF]  [Enviar por e-mail]   │
└────────────────────────────────────────────────────────────────────┘
```
