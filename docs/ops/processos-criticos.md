# Mapa de Processos Críticos — Lexend Scholar

**Versão**: 1.0
**Data**: Abril 2026
**Owner**: Operações

---

## Visão Geral

Este documento mapeia os 4 processos críticos do produto Lexend Scholar: matrícula, lançamento de notas, emissão de documentos e cobrança mensal. Para cada processo, são descritos atores, passos, pontos de falha e SLAs esperados.

---

## Processo 1: Matrícula de Novo Aluno

### Atores
- **Secretaria**: Responsável principal pelo processo
- **Responsável pelo aluno**: Fornece documentos e assina contratos
- **Diretor**: Aprovação em casos especiais (bolsas, necessidades especiais)
- **Sistema**: Valida dados, envia notificações automáticas

### Fluxo Principal

```
[Responsável] → Solicita matrícula (presencial, website, ou telefone)
      ↓
[Secretaria] → Cadastra aluno no sistema (dados pessoais, responsáveis, saúde)
      ↓
[Sistema] → Valida CPF do responsável + verifica duplicidade de aluno
      ↓
[Secretaria] → Atribui turma e configura dados financeiros (mensalidade, vencimento)
      ↓
[Sistema] → Gera contrato de matrícula em PDF para assinatura
      ↓
[Responsável] → Assina contrato (digital via link ou físico)
      ↓
[Sistema] → Confirma matrícula, envia email/SMS de boas-vindas, cria conta do responsável
      ↓
[Responsável] → Primeiro acesso ao app com link de convite
```

### Passos Detalhados

| # | Passo | Ator | Sistema | Tempo Esperado |
|---|---|---|---|---|
| 1 | Receber solicitação e verificar vagas | Secretaria | Verificar turma | 5 min |
| 2 | Cadastrar dados do aluno | Secretaria | Validar e salvar | 8 min |
| 3 | Validar documentos | Secretaria | OCR básico | 5 min |
| 4 | Atribuir turma | Secretaria | Verificar capacidade | 2 min |
| 5 | Configurar mensalidade | Secretaria | Criar plano financeiro | 3 min |
| 6 | Gerar e assinar contrato | Responsável + Sistema | PDF gerado | 5 min |
| 7 | Confirmar matrícula | Sistema (automático) | Notificação enviada | < 1 min |
| **Total** | | | | **~30 min** |

### Pontos de Falha

| Ponto | Risco | Probabilidade | Mitigação |
|---|---|---|---|
| CPF inválido do responsável | Alto: bloqueia cadastro | Baixa | Validação em tempo real com dígito verificador |
| Turma sem vagas | Médio: frustra interessado | Média | Exibir vagas disponíveis antes de iniciar |
| Email inválido | Alto: responsável não recebe convite | Baixa | Validação de formato + confirmação por SMS |
| Falha no upload de documentos | Baixo: atraso no processo | Média | Permitir upload posterior sem bloquear matrícula |
| Assinatura do contrato não concluída | Alto: matrícula incompleta | Média | Lembrete automático em 24h e 48h |
| Duplicidade de aluno | Médio: dados inconsistentes | Baixa | Busca por CPF + nome antes do cadastro |

### SLA
- **Tempo total de matrícula**: ≤ 30 minutos (operação normal)
- **Tempo de envio de convite ao responsável**: ≤ 5 minutos após confirmação
- **Prazo máximo para assinatura do contrato**: 3 dias úteis (com lembretes automáticos)

---

## Processo 2: Lançamento de Notas

### Atores
- **Professor**: Lança as notas de cada avaliação
- **Coordenador Pedagógico**: Revisão e aprovação (opcional, configurável)
- **Sistema**: Calcula médias, gera alertas, notifica responsáveis
- **Responsável**: Recebe notificação das notas

### Fluxo Principal

```
[Professor] → Aplica avaliação (prova, trabalho, etc.)
      ↓
[Professor] → Acessa módulo de notas no app
      ↓
[Professor] → Cria avaliação (nome, data, peso, valor máximo)
      ↓
[Professor] → Lança notas de cada aluno
      ↓
[Sistema] → Calcula média atualizada automaticamente
      ↓
[Sistema] → Notifica responsáveis sobre nova nota publicada (push notification)
      ↓
[Sistema] → Gera alerta se aluno ficou abaixo da média mínima
      ↓
[Coordenador] → (Opcional) Revisão e fechamento do bimestre
```

### Pontos de Falha

| Ponto | Risco | Probabilidade | Mitigação |
|---|---|---|---|
| Professor lança nota errada | Alto: impacto no boletim | Média | Confirmação antes de salvar + edição por 7 dias |
| Nota lançada para aluno errado | Alto: dados incorretos | Baixa | Mostrar foto do aluno ao lado do nome |
| Cálculo de média incorreto | Crítico: reprovação indevida | Muito baixa | Testes automatizados cobrindo todas as fórmulas |
| Responsável não recebe notificação | Médio: perda de comunicação | Baixa | APNS com retry + fallback por email |
| Bimestre fechado sem todas as notas | Alto: lacuna no boletim | Média | Alerta ao coordenador antes do fechamento |

### SLA
- **Disponibilidade do módulo de notas**: 99,5% (conforme tier)
- **Tempo de processamento e cálculo de média**: ≤ 3 segundos
- **Envio de notificação ao responsável**: ≤ 5 minutos após lançamento
- **Janela de edição de nota**: 7 dias após lançamento (após isso, requer autorização do coordenador)

---

## Processo 3: Emissão de Documentos Escolares

### Atores
- **Responsável**: Solicita o documento (presencialmente, pelo app ou email)
- **Secretaria**: Processa e emite o documento
- **Diretor**: Assina digitalmente (automatizado, via certificado digital)
- **Sistema**: Gera PDF, aplica assinatura, cria QR Code de verificação

### Fluxo Principal

```
[Responsável] → Solicita documento (pessoalmente ou pelo app)
      ↓
[Secretaria] → Identifica aluno no sistema
      ↓
[Secretaria] → Seleciona tipo de documento e configura parâmetros
      ↓
[Sistema] → Verifica dados (aluno matriculado, período válido, etc.)
      ↓
[Sistema] → Gera PDF com dados preenchidos
      ↓
[Sistema] → Aplica assinatura digital do responsável legal
      ↓
[Sistema] → Gera QR Code único de verificação
      ↓
[Secretaria] → Revisa preview e confirma emissão
      ↓
[Sistema] → Registra emissão no histórico + envia ao responsável
      ↓
[Responsável] → Recebe documento por email ou baixa no app
```

### Pontos de Falha

| Ponto | Risco | Probabilidade | Mitigação |
|---|---|---|---|
| Dados desatualizados do aluno | Médio: documento incorreto | Baixa | Alertar secretaria sobre campos não preenchidos |
| Certificado digital expirado | Alto: assinatura inválida | Baixa | Alerta 30 dias antes da expiração + renovação automática |
| QR Code de verificação offline | Médio: documento sem verificação | Baixa | Emissão online obrigatória para QR Code |
| Frequência não lançada no período | Alto: declaração de frequência incorreta | Média | Bloquear emissão se frequência do período está incompleta |
| Email de entrega retornado | Médio: responsável não recebe | Baixa | Fallback por WhatsApp + disponibilizar no app |

### SLA
- **Tempo de geração do documento**: ≤ 30 segundos
- **Tempo de entrega por email**: ≤ 5 minutos
- **Disponibilidade do serviço de emissão**: 99,5%
- **Validade do QR Code de verificação**: Permanente (enquanto escola ativa no sistema)

---

## Processo 4: Cobrança Mensal de Mensalidades

### Atores
- **Sistema (automático)**: Gera cobranças, envia boletos/PIX, registra pagamentos
- **Secretaria/Financeiro**: Monitora inadimplência, registra pagamentos manuais
- **Responsável**: Recebe cobrança, realiza pagamento
- **Stripe**: Processa pagamentos com cartão de crédito
- **Banco (via Boleto Cloud)**: Processa boletos e PIX

### Fluxo Principal

```
[Sistema] → No dia configurado (ex: dia 1 do mês), gera cobranças para todos os alunos ativos
      ↓
[Sistema] → Cria invoice no Stripe com os dados da mensalidade
      ↓
[Sistema] → Gera boleto bancário / QR Code PIX via Boleto Cloud
      ↓
[Sistema] → Envia notificação push + email para o responsável financeiro
      ↓
[Responsável] → Realiza pagamento (app/boleto/PIX/cartão)
      ↓
[Stripe/Banco] → Confirma pagamento via webhook
      ↓
[Sistema] → Atualiza status para "Pago", emite recibo/NFS-e automática
      ↓
[Sistema] → (Se não pago até o vencimento) Inicia fluxo de inadimplência
```

### Fluxo de Inadimplência

```
Vencimento + 1 dia → Notificação push + email: "Mensalidade em aberto"
Vencimento + 3 dias → Notificação WhatsApp (se integrado)
Vencimento + 7 dias → Email de aviso formal com juros calculados
Vencimento + 15 dias → Notificação ao diretor + bloqueio parcial (acesso somente leitura para responsável)
Vencimento + 30 dias → Relatório para cobrança manual / negativação (a critério da escola)
```

### Pontos de Falha

| Ponto | Risco | Probabilidade | Mitigação |
|---|---|---|---|
| Falha na geração de cobranças | Crítico: escola sem receita | Muito baixa | Jobs idempotentes com retry + alertas no Slack |
| Webhook Stripe não processado | Alto: pagamento confirmado mas não registrado | Baixa | Retry com exponential backoff + verificação diária |
| Boleto gerado com dados errados | Alto: pagamento não identificado | Baixa | Validação de CNPJ/CPF do responsável antes da geração |
| Falta de saldo/limite do responsável | Médio: inadimplência involuntária | Média | Retry automático em D+3 para cartão cadastrado |
| Juros calculados incorretamente | Alto: conflito com responsável | Muito baixa | Testes automatizados de cálculo de juros |
| NFS-e não emitida | Médio: problemas fiscais para escola | Baixa | Retry automático + alerta para a secretaria |

### SLA
- **Geração das cobranças mensais**: Até 06h00 do dia configurado
- **Entrega de boleto/PIX ao responsável**: ≤ 30 minutos após geração
- **Confirmação de pagamento no sistema**: ≤ 5 minutos após webhook do Stripe/banco
- **Emissão de NFS-e**: ≤ 30 minutos após confirmação de pagamento
- **Relatório de inadimplência disponível**: Atualizado em tempo real

---

## Monitoramento de Processos Críticos

Todos os processos críticos têm métricas monitoradas via dashboard operacional:

| Métrica | Frequência de Monitoramento | Alerta |
|---|---|---|
| Taxa de sucesso de matrículas | Diária | < 95% → Slack #ops |
| Notas lançadas sem entrega de notificação | Tempo real | > 1% falha → PagerDuty |
| Documentos emitidos com erro | Tempo real | Qualquer erro → Slack #bugs |
| Cobranças geradas vs esperadas | No dia de cobrança | Divergência → PagerDuty |
| Pagamentos confirmados vs pendentes | Horária | > 5% divergência → Slack #financeiro |
