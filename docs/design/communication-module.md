# Módulo de Comunicação Escola-Responsável

> Design do sistema de comunicação integrado do Lexend Scholar.
> Última revisão: 2026-04-12.

---

## Visão Geral

O módulo de comunicação centraliza toda a troca de informações entre escola e família, eliminando o uso de WhatsApp pessoal, bilhetinhos e e-mails dispersos. Suporta dois tipos de comunicação:

1. **Comunicados** — mensagens unidirecionais da escola para grupos (turma, série, escola toda)
2. **Mensagens** — conversa bidirecional entre secretaria/professor e responsável específico

---

## Wireframe — Caixa de Entrada (iOS)

```
┌── AppShell: Tab "Mensagens" ───────────────────────────────────────┐
│  Comunicação                           [+ Novo ✏️]                 │
│                                                                     │
│  [🔍 Buscar mensagens...]                                           │
│                                                                     │
│  ── COMUNICADOS ──────────────────────────────────────────────    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ 📢 Reunião de Pais — 1º Bimestre               Hoje, 09:15  │  │
│  │    Para: Toda a escola (342 alunos)                         │  │
│  │    "A reunião de pais e mestres do 1º bimestre será..."     │  │
│  │    Leituras: 287/342 (83%)                          [●●●○○] │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ ⚠️  Alerta: Frequência Baixa — Lucas Silva      Ontem, 14:30 │  │
│  │    Para: Roberto Alves (pai de Lucas Silva 6B)              │  │
│  │    "Informamos que seu filho Lucas está com frequên..."     │  │
│  │    Lido: Sim  ✓✓  14:52                                     │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ── MENSAGENS ────────────────────────────────────────────────    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ [RA] Roberto Alves                              Ontem, 18:44 │  │
│  │      Re: Alerta de Frequência                               │  │
│  │      "Ok, ele estava doente. Vou enviar o atestado..."      │  │
│  │                                                    ✓✓ lido  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ [MA] Maria Aparecida                           08 Abr, 10:20 │  │
│  │      Dúvida sobre nota de Ciências                          │  │
│  │      "Olá, gostaria de saber como foi calculada a nota..."  │  │
│  │                                                    • não lido│  │
│  └─────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

---

## Wireframe — Caixa de Entrada (Web Admin)

```
┌── Painel Web: Comunicação ─────────────────────────────────────────┐
│  Comunicação                           [+ Novo Comunicado]  [+ Mensagem]│
│                                                                     │
│  ┌──────────────────────┐  ┌────────────────────────────────────┐  │
│  │  FILTROS             │  │  THREAD ATIVA                      │  │
│  │                      │  │                                    │  │
│  │  Tipo:               │  │  Roberto Alves — pai de Lucas 6B   │  │
│  │  ● Todos             │  │  Último contato: Ontem, 18:44      │  │
│  │  ○ Comunicados       │  │  ────────────────────────────      │  │
│  │  ○ Mensagens         │  │                                    │  │
│  │                      │  │  10 Abr, 14:30                     │  │
│  │  Status:             │  │  ┌──────────────────────────────┐  │  │
│  │  ● Todos             │  │  │ Escola → Roberto             │  │  │
│  │  ○ Não lidos (2)     │  │  │ "Informamos que seu filho    │  │  │
│  │  ○ Aguardando resp.  │  │  │  Lucas está com frequência   │  │  │
│  │                      │  │  │  de 68%, abaixo do mínimo    │  │  │
│  │  ─────────────────── │  │  │  de 75%..."                  │  │  │
│  │  📢 Reunião Pais     │  │  └──────────────────────────────┘  │  │
│  │     Hoje, 09:15      │  │  ✓✓ Lido: 10 Abr às 14:52         │  │  │
│  │     83% lidos        │  │                                    │  │  │
│  │                      │  │  10 Abr, 18:44                     │  │  │
│  │  ⚠️  Alerta Lucas    │  │  ┌──────────────────────────────┐  │  │
│  │     Ontem, 14:30     │  │  │ Roberto → Escola             │  │  │
│  │     1 pessoa         │  │  │ "Ok, ele estava doente.      │  │  │
│  │                      │  │  │  Vou enviar o atestado       │  │  │
│  │  [RA] Roberto Alves  │  │  │  médico amanhã."             │  │  │
│  │     Ontem, 18:44 ●   │  │  └──────────────────────────────┘  │  │
│  │                      │  │  ✓✓ Lido: 11 Abr às 09:01          │  │  │
│  │  [MA] Maria Aparecida│  │                                    │  │  │
│  │     08 Abr, 10:20 ●  │  │  ────────────────────────────      │  │  │
│  │                      │  │  [Responder...                ]    │  │  │
│  └──────────────────────┘  │  [Enviar ↑]  [Anexar 📎]          │  │  │
│                             └────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

---

## Fluxo — Envio de Comunicado para Turma Completa

```
Secretária/Diretor
       │
       ▼
1. Toca em [+ Novo Comunicado]
       │
       ▼
2. Seleciona destinatários:
   ● Toda a escola
   ○ Por série (6º Ano, 7º Ano...)
   ○ Por turma (6A, 6B, 7A...)
   ○ Por turno (Manhã, Tarde)
       │
       ▼
3. Preenche o comunicado:
   - Título (obrigatório)
   - Corpo da mensagem (texto rico: negrito, lista, link)
   - Anexos (PDF, imagem — max 20MB)
   - Prioridade: Normal / Urgente
   - Solicitar confirmação de leitura: Sim / Não
       │
       ▼
4. Pré-visualização no formato que o responsável verá
       │
       ├── [Cancelar] → descarta rascunho
       ├── [Salvar rascunho] → salva para editar depois
       └── [Enviar agora] / [Agendar para: data/hora]
              │
              ▼
5. Sistema processa envio:
   - Push notification para todos os responsáveis do grupo
   - Comunicado aparece na caixa de entrada do app
   - E-mail de fallback para responsáveis sem o app instalado
       │
       ▼
6. Relatório de leitura disponível em tempo real:
   - X de Y responsáveis leram
   - Lista de quem não leu (para reenvio manual)
```

---

## Fluxo — Envio de Mensagem para Aluno Específico

```
Professor/Secretária
       │
       ▼
1. Acessa perfil do aluno → aba "Comunicação"
   OU busca pelo nome do responsável na caixa de entrada
       │
       ▼
2. Toca em [+ Nova Mensagem] ou [Responder thread]
       │
       ▼
3. Compõe mensagem:
   - Texto livre
   - Anexo opcional (boletim, laudo, declaração)
   - Marca como: Informativo / Alerta / Urgente
       │
       ▼
4. Envia → responsável recebe push notification
       │
       ▼
5. Responsável responde pelo app (perfil Responsável)
       │
       ▼
6. Secretária/Professor recebe notificação de resposta
   - Badge no ícone de Comunicação
   - Lista de conversas mostra resposta não lida
```

---

## Push Notification — Previews por Tipo de Comunicado

### Comunicado Institucional (Normal)
```
┌─────────────────────────────────────────┐
│  🎓 Lexend Scholar                  agora│
│  Reunião de Pais — 1º Bimestre          │
│  A reunião acontecerá na sexta-feira,   │
│  18 de abril às 19h. Confirme presença. │
└─────────────────────────────────────────┘
```

### Alerta de Frequência
```
┌─────────────────────────────────────────┐
│  ⚠️ Lexend Scholar                  agora│
│  Atenção: Frequência de Lucas           │
│  Lucas Silva (6B) está com 68% de      │
│  frequência, abaixo do mínimo de 75%.  │
└─────────────────────────────────────────┘
```

### Alerta de Nota
```
┌─────────────────────────────────────────┐
│  📝 Lexend Scholar                  agora│
│  Nota lançada — Matemática              │
│  Prof. Carlos lançou as notas da        │
│  Prova 2. Lucas: 6.5. Toque para ver.  │
└─────────────────────────────────────────┘
```

### Comunicado Urgente
```
┌─────────────────────────────────────────┐
│  🚨 URGENTE — Lexend Scholar       agora │
│  Escola fechada amanhã                  │
│  Devido a problema na rede elétrica,   │
│  as aulas de amanhã estão suspensas.   │
└─────────────────────────────────────────┘
```

### Lembrete de Mensalidade
```
┌─────────────────────────────────────────┐
│  💰 Lexend Scholar                  agora│
│  Mensalidade vence amanhã               │
│  A mensalidade de Lucas (6B) no valor  │
│  de R$950 vence em 10/04. Pague via Pix│
└─────────────────────────────────────────┘
```

### Resposta de Mensagem
```
┌─────────────────────────────────────────┐
│  💬 Lexend Scholar                  agora│
│  Nova resposta de Roberto Alves         │
│  "Ok, vou enviar o atestado médico     │
│  amanhã para a secretaria."            │
└─────────────────────────────────────────┘
```

---

## Regras do Módulo de Comunicação

### Quem pode enviar

| Papel | Pode enviar comunicado | Pode enviar mensagem | Para quem |
|---|:---:|:---:|---|
| Diretor | Sim | Sim | Escola toda / turma / responsável específico |
| Coordenador | Sim | Sim | Turma / responsável específico |
| Secretária | Sim | Sim | Escola toda / turma / responsável específico |
| Professor | Não | Sim | Responsáveis de alunos das suas turmas |
| Responsável | Não | Sim | Secretaria / escola (não inicia com professor) |
| Aluno | Não | Não | — |

### Quem recebe

- **Comunicado para turma:** todos os responsáveis de alunos ativos da turma.
- **Comunicado para escola:** todos os responsáveis de alunos ativos.
- **Mensagem individual:** apenas o(s) responsável(is) do aluno específico.
- **Confirmação de leitura:** opcional por comunicado. Se ativada, responsável vê botão "Confirmar leitura" no app.

### Histórico de Leitura

- Cada mensagem registra: data/hora de entrega, data/hora de abertura, canal (push app / e-mail fallback).
- Escola pode exportar relatório de leitura de um comunicado: lista de quem leu, quem não leu, canal.
- Histórico de conversas é mantido por 5 anos (conformidade com LGPD e regulamentações educacionais).
- Responsável pode solicitar exclusão de mensagens via solicitação LGPD (prazo: 30 dias).

### Notificações Push

- Responsáveis recebem push apenas para o(s) filho(s) vinculado(s) ao seu cadastro.
- Configuração de notificações disponível no app: o responsável pode desativar categorias (ex.: notas sim, financeiro não).
- Comunicados urgentes sempre entregues (não podem ser desativados individualmente).
- Silêncio noturno: notificações não urgentes não são enviadas entre 22h e 07h.

### Integração com Outros Módulos

- **Frequência:** faltas abaixo de 75% disparam alerta automático ao responsável.
- **Notas:** lançamento de notas pode ser configurado para notificar responsável automaticamente.
- **Financeiro:** vencimento de mensalidade gera lembrete automático (3 dias antes, no dia, 3 dias depois).
- **Matrícula:** confirmação e documentação pendente geram comunicados automáticos.
