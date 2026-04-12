# SOP: Onboarding de Nova Escola — Lexend Scholar

**Versão**: 1.0
**Owner**: Customer Success / Operações
**Última atualização**: Abril 2026

---

## Visão Geral

Este SOP define o processo de onboarding de uma nova escola no Lexend Scholar, desde a assinatura do contrato até a escola operar de forma autônoma. O objetivo é garantir que cada escola tenha uma experiência de primeiro acesso positiva e chegue ao "primeiro valor" (First Value) em menos de 1 hora.

**First Value**: Escola com pelo menos 1 turma criada, 1 professor convidado e 5 alunos cadastrados.

---

## Fase 1: Pré-Onboarding (D-1 a D-3 antes do acesso)

### Responsável: Customer Success (ou Founder na fase inicial)

**Checklist de preparação:**

- [ ] Contrato assinado e faturamento configurado no Stripe
- [ ] Informações básicas coletadas (via formulário de kickoff):
  - Nome completo da escola e razão social
  - CNPJ da escola
  - Nome do diretor/responsável
  - Quantidade de alunos (para verificar plano correto)
  - Quantidade de turmas
  - Turnos (matutino, vespertino, integral)
  - Ano letivo vigente (início e fim)
  - Sistema atual que usam (para planejar migração)
- [ ] Escola criada no sistema (pelo time Lexend Scholar):
  - Criar tenant da escola no banco de dados
  - Configurar plano e limites (qtd de alunos, usuários)
  - Ativar features do plano contratado
- [ ] Email de boas-vindas agendado para envio no dia do onboarding

---

## Fase 2: Primeiro Acesso e Configuração Inicial

### Duração estimada: 45-60 minutos
### Formato: Videoconferência (Zoom/Google Meet) ou presencial

### Passo 1: Acesso ao sistema (5 min)

1. Enviar link de primeiro acesso para o diretor: `app.lexendscholar.com/welcome?token=XXX`
2. Diretor cria a senha e entra no sistema
3. Verificar que o app iOS foi baixado e login foi feito com sucesso
4. Verificar que o perfil da escola está pré-preenchido com os dados do contrato

**Possíveis problemas:**
- Email do convite não chegou → reenviar via dashboard admin
- Erro ao criar senha → suporte técnico em tempo real via chat

---

### Passo 2: Configuração da escola (10 min)

Guiar o diretor pelas configurações básicas:

1. **Logo e identidade**: Carregar logo da escola (ícone que aparece em documentos)
2. **Dados da escola**: Verificar nome, CNPJ, endereço, telefone
3. **Responsável legal**: Nome e cargo do diretor (aparece nas declarações)
4. **Ano letivo**: Definir data de início e fim
5. **Calendário**: Marcar feriados municipais/estaduais relevantes
6. **Turnos**: Configurar os turnos ativos (Matutino 7h-12h, Vespertino 13h-18h, etc.)

---

### Passo 3: Criar as primeiras turmas (10 min)

Criar pelo menos 3 turmas como exemplo:

1. Acessar **Configurações → Turmas → Nova Turma**
2. Para cada turma definir:
   - Nome da turma (ex: 3A)
   - Série (3º Ano do Ensino Fundamental)
   - Turno
   - Capacidade máxima de alunos
3. Salvar e repetir para as turmas principais

**Dica**: Para escolas com muitas turmas, oferecer a importação em massa via planilha.

---

### Passo 4: Convidar professores (10 min)

1. Acessar **Configurações → Usuários → Convidar Usuário**
2. Para cada professor:
   - Nome completo
   - Email
   - Perfil: Professor
   - Turmas que leciona
3. Sistema envia email com convite automático
4. Guiar o diretor a convidar ao menos 2-3 professores chave

**Orientar o diretor**: Os professores receberão um email para criar conta. A senha é criada por eles — o sistema nunca tem acesso às senhas.

---

### Passo 5: Importação de dados de alunos (15 min)

**Opção A: Importação em massa (recomendada para escolas com 50+ alunos)**

1. Baixar o template de importação: Secretaria → Alunos → Importar → Baixar Template
2. Preencher o template com os dados (nome, data de nascimento, turma, responsáveis)
3. Fazer upload do arquivo preenchido
4. Revisar o preview de importação
5. Confirmar a importação

**Opção B: Cadastro manual (escolas pequenas ou pilotos)**

1. Cadastrar os primeiros 5-10 alunos manualmente para aprender o processo
2. Seguir o guia [Como cadastrar um aluno](../support/hc-como-cadastrar-aluno.md)

**Meta mínima para First Value**: 5 alunos cadastrados em pelo menos 1 turma.

---

### Passo 6: Primeiro lançamento de frequência (5 min)

Com um professor já convidado (pode ser o próprio diretor com perfil de professor):

1. Abrir o app iOS
2. Acessar o módulo de Frequência
3. Lançar a frequência de uma turma (mesmo que com dados de teste)
4. Verificar que os dados aparecem no painel do diretor em tempo real

Este passo é crucial para o professor sentir o valor do produto imediatamente.

---

## Fase 3: Treinamento da Equipe

### Duração: 1-2 horas adicionais (pode ser em sessão separada)

### Por perfil:

**Sessão para Secretaria (60 min):**
- Cadastro de alunos (em massa e individual)
- Emissão de declarações e documentos
- Módulo financeiro: cobranças, pagamentos, inadimplência
- Atualização de dados de alunos
- Relatórios da secretaria

**Sessão para Professores (30 min):**
- Lançamento de frequência (demo ao vivo)
- Lançamento de notas e avaliações
- Envio de comunicados para responsáveis
- Registro de ocorrências

**Sessão para Diretor (30 min):**
- Dashboard de gestão
- Relatórios de desempenho e frequência
- Configurações avançadas
- Como monitorar inadimplência

---

## Fase 4: Migração de Dados (se aplicável)

Para escolas migrando de outro sistema:

### Dados a migrar:
- Lista de alunos (nome, data nascimento, CPF, turma, responsáveis)
- Histórico financeiro (opcional — cobranças em aberto)
- Histórico acadêmico (opcional — notas de anos anteriores)

### Processo:
1. Exportar dados do sistema atual (CSV ou Excel)
2. Time Lexend Scholar mapeia e normaliza os dados
3. Importação em massa via ferramenta de admin
4. Validação com a secretaria: verificar amostra de 10% dos registros
5. Confirmação e assinatura de aceite da migração

**SLA de migração**: Até 5 dias úteis para escolas com até 500 alunos.

---

## Fase 5: Acompanhamento Pós-Onboarding

### Semana 1: Check-in diário (5 min)

- Verificar no sistema se alunos foram cadastrados
- Verificar se professores fizeram login
- Verificar se frequência foi lançada ao menos 1 vez
- Responder dúvidas via chat de suporte

### Semana 2: Check-in em D+7

- Reunião de 30 min via videoconferência
- Perguntas:
  - Alguma dificuldade no uso?
  - Funcionalidade mais usada?
  - Funcionalidade que sente falta?
  - NPS: "Em uma escala de 0-10, o quanto recomendaria o Lexend Scholar?"

### Mês 1: Reunião de 30 dias

- Revisão do uso: quantos alunos, quantas frequências lançadas, documentos emitidos
- Onboarding completo? Se não, identificar bloqueios
- Apresentar features que ainda não usaram
- Colher depoimento para case study (se NPS > 8)

---

## Critérios de Conclusão do Onboarding

O onboarding é considerado **concluído** quando:

- [ ] Todos os alunos ativos cadastrados no sistema
- [ ] Todos os professores com acesso e ao menos 1 login feito
- [ ] Frequência lançada em ao menos 1 semana completa
- [ ] Secretaria emitiu ao menos 1 documento
- [ ] Módulo financeiro configurado (mensalidades definidas)
- [ ] Responsáveis com acesso ao app (ao menos 30% dos alunos)
- [ ] NPS de onboarding coletado

---

## Handoff para Suporte Regular

Após conclusão do onboarding, o cliente é transferido para o fluxo de suporte padrão:
- Crisp: canal de suporte (tier conforme plano)
- Linear: issues abertas pelo cliente entram no backlog
- CSM: revisão mensal para clientes Enterprise

---

## Template de Email de Boas-Vindas

```
Assunto: Sua escola no Lexend Scholar — acesse agora!

Olá, {Nome do Diretor}!

Estamos felizes em ter a {Nome da Escola} como parte do Lexend Scholar.

Seu acesso está pronto. Clique abaixo para criar sua senha e fazer o primeiro login:

[ACESSAR O LEXEND SCHOLAR]

Sugestão: baixe também o app no iPhone para gerenciar sua escola de qualquer lugar:
[BAIXAR NA APP STORE]

Nossa equipe está aqui para te ajudar a configurar tudo. Nossa sessão de onboarding
está agendada para {data e hora da sessão}.

Qualquer dúvida antes disso, basta responder este email.

Com carinho,
Equipe Lexend Scholar
suporte@lexendscholar.com
```
