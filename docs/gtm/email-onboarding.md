# Sequência de Email Onboarding — Lexend Scholar

**Versão**: 1.0
**Owner**: Growth / Marketing
**Ferramenta**: MailerLite ou ConvertKit
**Trigger**: Escola completa o primeiro pagamento e é ativada
**Última atualização**: Abril 2026

---

## Visão Geral da Sequência

A sequência tem **7 emails** ao longo de 30 dias, projetados para levar a escola do primeiro acesso ao uso autônomo e satisfatório do produto. O objetivo é garantir que o cliente chegue ao **First Value** rapidamente e desenvolva o hábito de uso.

**Objetivo da sequência:**
- Reduzir churn nos primeiros 30 dias
- Aumentar o número de features ativadas por escola
- Coletar feedback antes que o cliente desista silenciosamente
- Criar conexão humana com a marca

---

## Email 1: Boas-Vindas + Primeiro Acesso (Dia 0)

**Assunto**: Sua escola no Lexend Scholar — acesse agora! 🎉
**Pré-header**: Em 15 minutos você já pode lançar a primeira chamada digital
**Tipo**: Transacional + Onboarding
**De**: Marlow Sousa <marlow@lexendscholar.com>

---

Olá, {nome_diretor}!

É com muita alegria que recebemos a {nome_escola} no Lexend Scholar.

Seu acesso está pronto. Aqui está tudo que você precisa para o primeiro dia:

**▶ Acessar o sistema agora:**
[ENTRAR NO LEXEND SCHOLAR] → app.lexendscholar.com

**📱 Baixar o app no iPhone:**
[BAIXAR NA APP STORE] → link da App Store

**Nos primeiros 15 minutos, faça isso:**
1. Faça login e explore o painel do diretor
2. Crie sua primeira turma (leva 2 minutos)
3. Convide um professor para testar a frequência digital

Nossa equipe está disponível para ajudar. Responda este email a qualquer momento ou acesse o chat de suporte no app.

Com carinho,
Marlow Sousa
Co-fundador, Lexend Scholar
marlow@lexendscholar.com | +55 11 XXXX-XXXX

P.S.: Se preferir, agende uma sessão de onboarding de 30 minutos com nossa equipe: [AGENDAR SESSÃO]

---

**Configurações técnicas:**
- Horário de envio: Imediatamente após ativação da conta
- Rastrear abertura: Sim
- Rastrear clique: Sim (botão principal e App Store)
- Tag no cliente: onboarding-started

---

## Email 2: Como Cadastrar Seus Primeiros Alunos (Dia 1)

**Assunto**: {nome_diretor}, como está indo? Hora de cadastrar seus alunos
**Pré-header**: Importar 300 alunos leva menos de 10 minutos com nosso template
**Tipo**: Produto / Educação
**De**: Marlow Sousa <marlow@lexendscholar.com>

---

Olá, {nome_diretor}!

Esperamos que o primeiro acesso tenha sido tranquilo. O próximo passo é cadastrar os alunos — e temos duas formas de fazer isso:

**Opção 1: Importar em massa (recomendada para escolas com 50+ alunos)**

Baixe nosso template Excel, preencha com os dados dos alunos e faça upload. Em 5 minutos você importa centenas de alunos de uma vez.

[BAIXAR TEMPLATE DE IMPORTAÇÃO]

**Opção 2: Cadastrar individualmente**

Ideal para escolas menores ou para aprender o sistema passo a passo.
Acesse Secretaria → Alunos → Novo Aluno.

[VER GUIA PASSO A PASSO]

**O que você precisa ter em mãos:**
- Lista de alunos com nome e data de nascimento
- Turma de cada aluno
- Nome e contato do responsável (para ativar o app dos pais)

Após cadastrar os alunos, os professores já podem começar a lançar frequência!

Qualquer dúvida, estou aqui.

Marlow

---

**Configurações técnicas:**
- Horário: 09h00 BRT do dia seguinte ao email 1
- Condição: Enviar apenas se escola ainda não cadastrou alunos (verificar via API)
- Tag: onboarding-step-2

---

## Email 3: Dica — Frequência em 30 Segundos (Dia 3)

**Assunto**: Seus professores podem fazer a chamada em 30 segundos — veja como
**Pré-header**: Adeus lista de papel: professores economizam 2h por semana
**Tipo**: Produto / Educação
**De**: Equipe Lexend Scholar <suporte@lexendscholar.com>

---

Olá, {nome_diretor}!

Uma das features mais amadas pelos professores que usam o Lexend Scholar é a frequência digital. E o motivo é simples: **a chamada leva menos de 30 segundos**.

**Como funciona:**
1. Professor abre o app no iPhone
2. Toca em "Frequência" — a turma do dia já aparece
3. Toca apenas nos alunos AUSENTES (o resto já aparece como presente)
4. Toca em "Salvar"
5. Pronto — o responsável recebe notificação automática se o filho faltou

**Impacto real:**
Um professor com 5 turmas economiza quase **2 horas por semana** só no processo de chamada. No mês, são mais de 8 horas dedicadas ao que importa: ensinar.

[CONVIDAR PROFESSORES AGORA]

---

**Dica bônus**: O app funciona mesmo sem WiFi. O professor faz a chamada offline e os dados sincronizam automaticamente quando ele voltar à área de cobertura.

Abraço,
Equipe Lexend Scholar

---

**Configurações técnicas:**
- Horário: Dia 3 às 07h30 BRT (antes da aula)
- Condição: Enviar se menos de 50% das turmas tiveram frequência lançada
- Tag: onboarding-step-3

---

## Email 4: Como Emitir Declarações (Dia 7)

**Assunto**: Sua secretaria vai adorar isso: declarações em 30 segundos
**Pré-header**: Declaração de matrícula com QR Code de verificação — zero papelada
**Tipo**: Produto / Educação
**De**: Equipe Lexend Scholar <suporte@lexendscholar.com>

---

Olá, {nome_diretor}!

Uma das tarefas que mais consume tempo da secretaria é a emissão de declarações. Com o Lexend Scholar, isso leva menos de 1 minuto.

**Declarações que você já pode emitir:**
✓ Declaração de matrícula
✓ Atestado de frequência
✓ Histórico escolar parcial
✓ Atestado de escolaridade

**O diferencial**: Todos os documentos têm **QR Code de verificação**. Qualquer empresa ou instituição pode escanear e confirmar a autenticidade do documento sem precisar ligar para a escola.

[EXPERIMENTAR EMISSÃO DE DECLARAÇÃO]

**Passo a passo:**
Secretaria → Alunos → Selecionar aluno → Documentos → Emitir Declaração → PDF gerado automaticamente.

Simples assim. Sem Word, sem copiar e colar dados, sem erros de digitação.

Abraço,
Equipe Lexend Scholar

---

**Configurações técnicas:**
- Horário: Dia 7 às 09h00 BRT
- Tag: onboarding-step-4

---

## Email 5: Módulo Financeiro — Cobranças Automáticas (Dia 14)

**Assunto**: Chega de planilha de inadimplência — automatize em 10 minutos
**Pré-header**: Boleto, PIX ou cartão enviado automaticamente todo mês para os responsáveis
**Tipo**: Produto / Upsell
**De**: Marlow Sousa <marlow@lexendscholar.com>

---

Olá, {nome_diretor}!

Se você ainda está usando planilha para controlar as mensalidades, tenho uma boa notícia: você pode automatizar isso hoje.

**Como funciona o módulo financeiro:**

1. Configure o valor da mensalidade de cada turma
2. Defina o dia de vencimento (ex: todo dia 10)
3. Pronto — o sistema gera e envia o boleto/PIX automaticamente para cada responsável

**O que acontece automaticamente:**
- Boleto enviado com X dias de antecedência
- Lembrete no vencimento
- Aviso de atraso (com juros calculados automaticamente)
- Suspensão parcial após 15 dias de atraso
- Tudo registrado no histórico de cada aluno

**Resultado**: Escolas que ativam o módulo financeiro reportam redução de 30-40% na inadimplência no primeiro trimestre.

[CONFIGURAR MÓDULO FINANCEIRO]

Disponível a partir do plano Pro. Se você está no Basic e quer ativar, [clique aqui para fazer upgrade].

Marlow

---

**Configurações técnicas:**
- Horário: Dia 14 às 10h00 BRT
- Condição: Se o módulo financeiro não foi ativado
- Tag: onboarding-step-5, financial-upsell

---

## Email 6: Como Está Indo? Pedido de Feedback (Dia 21)

**Assunto**: {nome_diretor}, posso te fazer uma pergunta?
**Pré-header**: 2 minutos de feedback vão nos ajudar a melhorar o produto pra você
**Tipo**: Feedback / Relacionamento
**De**: Marlow Sousa <marlow@lexendscholar.com>
**Tom**: Pessoal, curto, conversacional

---

Olá, {nome_diretor}!

Faz 3 semanas que a {nome_escola} está usando o Lexend Scholar.

Tenho uma pergunta direta: **como está sendo a experiência até agora?**

Em uma escala de 0 a 10, o quanto você recomendaria o Lexend Scholar para outros diretores?

[0 — 1 — 2 — 3 — 4 — 5 — 6 — 7 — 8 — 9 — 10]
(cada número é um link que registra a resposta)

Independente da nota, adoraria saber o porquê. Pode responder diretamente neste email — eu leio pessoalmente.

O que está funcionando bem? O que poderia ser melhor? Tem alguma funcionalidade que faz falta?

Obrigado pela confiança,
Marlow
Co-fundador, Lexend Scholar

P.S.: Se tiver algum problema que ainda não resolvemos, me conta neste email. Vou pessoalmente garantir que seja resolvido.

---

**Configurações técnicas:**
- Horário: Dia 21 às 09h00 BRT
- Links de NPS: Cada número leva para formulário com campo de texto aberto
- Segmentar respostas: NPS < 7 → alerta imediato para o time; NPS ≥ 9 → solicitar depoimento
- Tag: nps-collected

---

## Email 7: Seu Primeiro Mês — Relatório de Uso (Dia 30)

**Assunto**: {nome_escola} no Lexend Scholar — o que aconteceu no primeiro mês
**Pré-header**: Frequência lançada, alunos cadastrados, declarações emitidas — veja o resumo
**Tipo**: Relatório / Celebração
**De**: Equipe Lexend Scholar <suporte@lexendscholar.com>

---

Olá, {nome_diretor}!

Primeiro mês completo! Aqui está o que aconteceu na {nome_escola} durante esse tempo:

**📊 Relatório de uso — {mês} de 2026**

👨‍🎓 Alunos cadastrados: **{alunos_cadastrados}**
📋 Frequências registradas: **{frequencias_lancadas}**
📄 Declarações emitidas: **{documentos_emitidos}**
👨‍👩‍👧 Responsáveis ativos no app: **{responsaveis_ativos}**
💰 Cobranças geradas: **R$ {valor_cobrado}**

---

**O que mais as escolas fazem no segundo mês:**

Agora que o básico está funcionando, estas são as features que os diretores mais ativam:

→ **Relatórios personalizados**: DRE da escola, inadimplência por turma
→ **Comunicados em massa**: Enviar aviso para todos os responsáveis de uma turma com 1 clique
→ **Alertas de evasão**: Sistema detecta alunos com risco de reprovar por falta

Quer explorar alguma dessas? [FALE COM NOSSO TIME]

---

**Obrigado por confiar no Lexend Scholar.**

Se tiver sugestões, críticas ou quiser indicar o sistema para outro diretor, estamos sempre disponíveis em suporte@lexendscholar.com.

Equipe Lexend Scholar

---

**Configurações técnicas:**
- Horário: Dia 30 às 10h00 BRT
- Dados do relatório: Puxar via API do banco de dados em tempo real
- Tag: onboarding-complete
- Próxima ação: Mover cliente para sequência de "Clientes Ativos" (comunicados mensais)

---

## Configuração Técnica da Sequência

### Ferramenta recomendada: MailerLite ou ConvertKit

**Por que MailerLite para early stage:**
- Gratuito até 1.000 assinantes e 12.000 emails/mês
- Automações visuais intuitivas
- Suporte a segmentação por comportamento via API
- Integração com Stripe e Supabase via Zapier/n8n

### Segmentação dinâmica

Os emails condicionais (Ex: "se não cadastrou alunos ainda") dependem de integração com a API do Lexend Scholar:

```javascript
// Webhook enviado para MailerLite/ConvertKit para atualizar propriedades do lead
// Chamado quando eventos importantes acontecem no sistema

async function updateEmailSubscriberProperties(schoolId: string) {
  const stats = await db.getSchoolOnboardingStats(schoolId);
  
  await mailerLite.subscribers.updateProperties(school.directorEmail, {
    students_count: stats.studentsCount,
    classes_count: stats.classesCount,
    attendance_sessions: stats.attendanceSessions,
    documents_issued: stats.documentsIssued,
    financial_module_active: stats.financialModuleActive,
    onboarding_progress: calculateProgress(stats)
  });
}
```

### Métricas de sucesso da sequência

| Métrica | Meta |
|---|---|
| Taxa de abertura média | ≥ 45% |
| Taxa de clique média | ≥ 12% |
| Churn nos primeiros 30 dias | ≤ 10% |
| NPS médio coletado (Email 6) | ≥ 35 |
| Escolas com todos os módulos ativos no D+30 | ≥ 60% |
