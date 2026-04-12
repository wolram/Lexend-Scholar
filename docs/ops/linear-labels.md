# Estrutura de Labels e Workflows no Linear — Lexend Scholar

**Versão**: 1.0
**Owner**: Operações / Engineering Lead
**Última atualização**: Abril 2026

---

## Visão Geral

Uma estrutura de labels bem definida no Linear é fundamental para:
- Filtrar e priorizar o trabalho rapidamente
- Gerar relatórios úteis (ex: quantos bugs P0 tivemos esse mês?)
- Comunicar status entre times diferentes
- Automatizar workflows com regras do Linear

---

## Estrutura de Labels

### Grupo 1: Priority (Prioridade)

| Label | Cor | Descrição |
|---|---|---|
| `P0` | Vermelho (#FF0000) | Crítico — production down, perda de dados |
| `P1` | Laranja (#FF6B00) | Alto — feature principal inoperante |
| `P2` | Amarelo (#FFCC00) | Médio — degradação com workaround possível |
| `P3` | Cinza (#999999) | Baixo — cosmético, sem impacto funcional |

**Regra**: Todo issue de tipo Bug deve ter um label P0-P3.

---

### Grupo 2: Type (Tipo)

| Label | Cor | Descrição |
|---|---|---|
| `Bug` | Vermelho claro (#FFD1D1) | Comportamento incorreto do sistema |
| `Feature` | Verde (#00CC66) | Nova funcionalidade |
| `Improvement` | Azul claro (#87CEEB) | Melhoria de funcionalidade existente |
| `Tech Debt` | Roxo (#9B59B6) | Refatoração, modernização, dívida técnica |
| `Documentation` | Cinza claro (#CCCCCC) | Documentação, runbooks, guias |
| `Research` | Lavanda (#E8D5FF) | Pesquisa, spike técnico, prova de conceito |
| `Security` | Vermelho escuro (#8B0000) | Vulnerabilidade de segurança ou conformidade |

---

### Grupo 3: Platform (Plataforma)

| Label | Cor | Descrição |
|---|---|---|
| `iOS` | Azul Apple (#0070F3) | Afeta o app iOS (Swift/SwiftUI) |
| `Android` | Verde Android (#3DDC84) | Afeta o app Android (Kotlin/Compose) |
| `Web` | Roxo (#6B48FF) | Afeta a plataforma web (Next.js) |
| `Backend` | Laranja escuro (#E67E22) | Afeta API, banco de dados, infraestrutura |
| `All Platforms` | Preto (#333333) | Afeta todas as plataformas |

**Regra**: Todo issue deve ter ao menos um label de Platform.

---

### Grupo 4: Status (Estados especiais)

| Label | Cor | Descrição |
|---|---|---|
| `Blocked` | Vermelho (#FF0000) | Issue bloqueado por outra issue ou dependência externa |
| `Needs Review` | Amarelo (#FFCC00) | Aguardando revisão técnica ou de produto antes de prosseguir |
| `Needs Design` | Rosa (#FF69B4) | Aguardando especificação ou assets de design |
| `Waiting Client` | Turquesa (#40E0D0) | Aguardando resposta ou informação do cliente |
| `Won't Fix` | Cinza escuro (#666666) | Issue reconhecido mas não será corrigido |
| `Duplicate` | Cinza (#AAAAAA) | Issue duplicado de outra issue |

---

### Grupo 5: Area (Área de Produto)

| Label | Cor | Descrição |
|---|---|---|
| `Acadêmico` | Verde musgo (#6B8E23) | Notas, frequência, turmas, alunos |
| `Financeiro` | Verde dinheiro (#2ECC71) | Cobranças, pagamentos, inadimplência |
| `Secretaria` | Azul (#3498DB) | Documentos, matrículas, cadastros |
| `Comunicação` | Laranja (#E67E22) | Push notifications, chat, avisos |
| `Compliance` | Vermelho escuro (#C0392B) | LGPD, segurança, auditoria |
| `Infrastructure` | Cinza (#95A5A6) | CI/CD, banco de dados, deploy |

---

## Como Configurar Labels no Linear

### Via Interface

1. Acesse o projeto **Lexend Scholar** no Linear
2. Vá em **Settings → Labels**
3. Clique em **"Add label"**
4. Para cada label: defina nome, cor e grupo
5. Repita para todos os labels listados acima

### Via API (automação)

```javascript
// Criar labels via Linear API (GraphQL)
const CREATE_LABEL = `
  mutation CreateLabel($input: IssueLabelCreateInput!) {
    issueLabelCreate(input: $input) {
      issueLabel {
        id
        name
        color
      }
    }
  }
`;

const labels = [
  { name: 'P0', color: '#FF0000', teamId: 'LEXEND_SCHOLAR_TEAM_ID' },
  { name: 'P1', color: '#FF6B00', teamId: 'LEXEND_SCHOLAR_TEAM_ID' },
  { name: 'Bug', color: '#FFD1D1', teamId: 'LEXEND_SCHOLAR_TEAM_ID' },
  // ... outros labels
];

for (const label of labels) {
  await linearClient.client.rawRequest(CREATE_LABEL, { input: label });
}
```

---

## Automações no Linear

O Linear permite configurar automações (Workflows) que automaticamente movem issues, adicionam labels ou notificam pessoas baseado em condições.

### Automação 1: Bug P0 → Notificar Slack

**Trigger**: Issue criado com labels `Bug` + `P0`
**Ação**: Postar mensagem no Slack `#incidentes`

Configurar em **Team → Workflows → Create workflow**:
```
IF issue created
AND labels contain [Bug, P0]
THEN post to Slack #incidentes: "🚨 Bug P0 criado: {issue.title} — {issue.url}"
```

### Automação 2: In Progress → Notificar assignee

**Trigger**: Issue movido para state "In Progress"
**Ação**: Enviar notificação para o assignee (built-in no Linear)

### Automação 3: Security → Auto-assign ao Security Lead

**Trigger**: Label `Security` adicionado a qualquer issue
**Ação**: Assignar automaticamente para o responsável de segurança

### Automação 4: Bug fechado → Verificar ticket Crisp

**Trigger**: Issue com label `Bug` movido para state "Done"
**Ação**: Via webhook do Linear → handler que fecha o ticket correspondente no Crisp
(Ver `linear-integration.md` para detalhes)

### Automação 5: Blocked → Alertar no Slack diariamente

**Trigger**: Issue com label `Blocked` há mais de 2 dias sem movimentação
**Ação**: Mensagem diária no Slack `#eng`: "Issue LS-XXX bloqueado há X dias: {título}"

---

## Fluxo de Estados (Workflow States)

### Estados do time Lexend Scholar

| Estado | Tipo | Descrição |
|---|---|---|
| `Backlog` | Backlog | Issues planejados mas não priorizados |
| `Triage` | Backlog | Bugs e requests novos aguardando avaliação |
| `Ready` | Unstarted | Priorizados e prontos para desenvolvimento |
| `In Progress` | Started | Sendo desenvolvido ativamente |
| `In Review` | Started | PR aberto, aguardando code review |
| `Staging` | Started | Deployado em staging, aguardando QA |
| `Done` | Completed | Resolvido e em produção |
| `Cancelled` | Cancelled | Cancelado (com motivo nos comentários) |

---

## Convenções de Uso

### Nomenclatura de issues

```
[Tipo] Descrição curta (≤ 60 caracteres)

Exemplos:
[Bug] Professor não consegue salvar frequência offline
[Feature] Relatório de frequência mensal por turma
[Improvement] Reduzir tempo de geração de PDF de declaração
[Debt] Migrar de REST para GraphQL no endpoint de alunos
```

### Uso de labels obrigatórios

Todo issue deve ter:
- **Type**: Bug / Feature / Improvement / Tech Debt / Documentation / Research / Security
- **Platform**: iOS / Android / Web / Backend / All Platforms
- **Priority**: P0 / P1 / P2 / P3 (obrigatório para bugs)

Opcionais mas recomendados:
- **Area**: qual módulo do produto é afetado
- **Status**: se há algo especial (Blocked, Needs Review, etc.)

---

## Boas Práticas para Issues no Linear

1. **Título descritivo**: "Botão quebrado" é ruim. "Botão 'Salvar' na tela de frequência não responde no iPhone 15" é bom.

2. **Descrição completa para bugs**:
   - Passos para reproduzir
   - Comportamento esperado vs observado
   - Device/OS/Versão
   - Screenshot ou gravação de tela

3. **Estimativas**: Usar story points (1, 2, 3, 5, 8, 13) para features e melhorias

4. **Subtarefas**: Usar sub-issues para tasks grandes (> 5 pontos)

5. **Links**: Sempre linkar PRs relevantes ao issue

6. **Comentários**: Documentar decisões tomadas durante o desenvolvimento no comentário do issue

7. **Fechar adequadamente**: Ao marcar como Done, adicionar comentário com:
   - O que foi feito
   - PR/commit relacionado
   - Como testar

---

## Revisão da Estrutura de Labels

Revisar e atualizar este documento:
- **Trimestralmente**: Verificar se labels estão sendo usados corretamente
- **Quando houver novo time/produto**: Adicionar labels de platform/area necessários
- **Após retrospectivas**: Ajustar com base em dificuldades encontradas
