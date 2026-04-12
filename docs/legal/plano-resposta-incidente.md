# Plano de Resposta a Incidentes de Dados — Lexend Scholar

**Versão**: 1.0
**Owner**: DPO (Marlow Sousa)
**Referência Legal**: LGPD Art. 48, Resolução CD/ANPD nº 4/2023
**Última atualização**: Abril 2026

---

## Visão Geral

Um incidente de dados é qualquer evento que resulte em acesso não autorizado, perda, alteração, divulgação, ou destruição de dados pessoais. Para o Lexend Scholar — que trata dados sensíveis de menores de idade — a resposta a incidentes deve ser rigorosa e coordenada.

**Obrigação legal**: A LGPD (Art. 48) exige comunicação à ANPD e aos titulares afetados em **prazo razoável** — a Resolução CD/ANPD nº 4/2023 define esse prazo como **72 horas** para a ANPD e prazo adequado para titulares.

---

## Classificação de Incidentes de Dados

| Nível | Descrição | Exemplos | Prazo de resposta |
|---|---|---|---|
| **Crítico** | Exposição em larga escala de dados sensíveis | Vazamento do banco de dados com dados de todos os alunos | Comunicar ANPD em até 72h |
| **Alto** | Acesso não autorizado a dados de usuários específicos | Invasão de conta de administrador com acesso a dados de alunos | Comunicar ANPD em até 72h |
| **Médio** | Perda de dados sem evidência de exposição externa | Backup corrompido, dados deletados sem intenção maliciosa | Avaliar necessidade de comunicação |
| **Baixo** | Incidente menor sem impacto provável a titulares | Email enviado para destinatário errado (sem dados sensíveis) | Registro interno |

---

## Fase 1: Detecção

### Como detectar um incidente de dados

**Fontes automáticas:**
- Alertas do Supabase: acessos incomuns, queries anômalas
- Sentry: erros de autorização em grande volume
- Cloudflare: picos de tráfego suspeitos, tentativas de força bruta
- AWS Security Hub / GuardDuty (se aplicável)

**Fontes manuais:**
- Reporte de cliente sobre dados incorretos ou acessados por outra pessoa
- Reporte de usuário sobre atividade suspeita na conta
- Descoberta interna por engenheiro ou funcionário
- Alerta de terceiro (pesquisador de segurança, jornalista)

### Ação imediata ao suspeitar de incidente:

1. **NÃO DELETAR** nenhum log, arquivo ou evidência — isso é obstrução
2. **NÃO COMPARTILHAR** publicamente antes da resposta organizada
3. Notificar imediatamente o DPO: privacidade@lexendscholar.com / WhatsApp direto
4. Registrar hora e forma de detecção

---

## Fase 2: Contenção

### Objetivo: Parar o incidente de se alastrar

**Ações imediatas (primeiros 30 minutos):**

1. **Isolar o sistema comprometido**:
   ```bash
   # Desabilitar acesso público ao endpoint comprometido
   # Vercel: configurar para maintenance mode
   # Supabase: revogar API keys comprometidas
   ```

2. **Revogar tokens de acesso suspeitos**:
   ```bash
   # Supabase: revogar JWT tokens de usuários suspeitos
   # No dashboard: Authentication → Users → Revoke sessions
   ```

3. **Bloquear IP suspeito** (se identificado):
   - Cloudflare: Security → WAF → IP Block Rules

4. **Preservar evidências**:
   - Exportar logs relevantes do período do incidente
   - Screenshot de dashboards de monitoramento
   - Registrar sequência de eventos em documento compartilhado

5. **Ativar equipe de resposta**:
   - DPO: coordenação geral e comunicação regulatória
   - CTO/Engineering Lead: resposta técnica
   - CEO/Founder: decisões executivas e comunicação com clientes Enterprise

---

## Fase 3: Erradicação

### Objetivo: Eliminar a causa raiz do incidente

**Investigação forense básica:**

1. Identificar como o incidente ocorreu:
   - Credencial comprometida?
   - Vulnerabilidade de software?
   - Erro humano?
   - Ataque externo?

2. Determinar o escopo exato:
   - Quais dados foram acessados/expostos?
   - Quantos titulares afetados?
   - Qual o período de exposição?
   - Os dados incluem menores de idade? (agravante legal)

3. Implementar o fix:
   - Corrigir a vulnerabilidade
   - Atualizar credenciais comprometidas
   - Reforçar controles de acesso

4. Validar que a causa raiz foi eliminada

---

## Fase 4: Recuperação

### Objetivo: Restaurar o serviço normal com segurança

1. **Restaurar sistemas** a partir de backup limpo (se necessário)
2. **Verificar integridade dos dados**: Comparar com último backup antes do incidente
3. **Monitoramento intensificado**: 72 horas de monitoramento reforçado pós-incidente
4. **Reabrir serviço gradualmente**: Verificar que não há evidência de comprometimento residual
5. **Comunicar a resolução** aos clientes afetados

---

## Fase 5: Comunicação à ANPD (72 horas)

### Quando comunicar

**Comunicar OBRIGATORIAMENTE** quando o incidente:
- Envolver dados sensíveis (saúde, financeiro, dados de crianças)
- Puder causar dano relevante aos titulares (discriminação, fraude, dano reputacional)
- Envolver grande número de titulares

**Não é necessário comunicar** incidentes que não puderem afeitar negativamente os titulares (ex: falha interna sem exposição de dados).

### Template de Comunicação à ANPD

```
COMUNICAÇÃO DE INCIDENTE DE SEGURANÇA - RESOLUÇÃO CD/ANPD Nº 4/2023

1. IDENTIFICAÇÃO DO CONTROLADOR
Nome: Lexend Scholar Ltda.
CNPJ: XX.XXX.XXX/0001-XX
Endereço: [endereço completo]
Encarregado de Dados (DPO): Marlow Sousa
Email do DPO: privacidade@lexendscholar.com

2. NATUREZA DO INCIDENTE
Descrição: [Descrição objetiva do que aconteceu]
Data e hora da ocorrência: [DD/MM/AAAA HH:MM BRT]
Data e hora da descoberta: [DD/MM/AAAA HH:MM BRT]

3. DADOS PESSOAIS ENVOLVIDOS
Categorias de dados: [ex: nome, email, data de nascimento, dados de saúde]
Categorias de titulares: [ex: alunos menores de idade, professores, responsáveis]
Número aproximado de titulares afetados: [número]
Inclui dados de crianças/adolescentes: [Sim/Não]

4. POSSÍVEIS CONSEQUÊNCIAS
[Descrever os riscos identificados para os titulares afetados]

5. MEDIDAS ADOTADAS
Antes do incidente: [controles de segurança existentes]
Após o incidente: [ações de contenção e erradicação]
Planejadas: [ações preventivas futuras]

6. COMUNICAÇÃO AOS TITULARES
Titulares foram comunicados: [Sim/Não/Em andamento]
Data de comunicação: [DD/MM/AAAA]
Meio de comunicação: [email/push notification/carta]

7. INFORMAÇÕES ADICIONAIS
[Quaisquer outras informações relevantes]

Declaramos que as informações acima são verdadeiras.

[Cidade], [data]

_______________________
Marlow Sousa
DPO — Lexend Scholar
```

**Enviar via**: gov.br/anpd → Atendimento → Comunicação de Incidente de Segurança

---

## Fase 5b: Comunicação aos Titulares

### Quando comunicar titulares

A comunicação aos titulares é obrigatória quando o incidente puder causar riscos ou danos relevantes a eles.

### Template de Comunicação para Titulares (Responsáveis de Alunos)

```
Assunto: Comunicado importante sobre segurança dos dados — Lexend Scholar

Prezado(a) {Nome do Responsável},

Precisamos informar que identificamos um incidente de segurança que pode ter 
afetado os dados do(a) {Nome do Aluno} cadastrado(a) na {Nome da Escola}.

O QUE ACONTECEU:
{Descrição clara e sem jargão técnico do incidente}

QUAIS DADOS FORAM AFETADOS:
{Lista dos tipos de dados que podem ter sido expostos}

O QUE ESTAMOS FAZENDO:
- Contivemos o incidente em {data}
- Corrigimos a vulnerabilidade que possibilitou o incidente
- Notificamos a Autoridade Nacional de Proteção de Dados (ANPD)
- Reforçamos os controles de segurança do sistema

O QUE VOCÊ PODE FAZER:
{Ações recomendadas para os titulares, se aplicável}
- Altere sua senha no app: Perfil → Segurança → Alterar Senha
- Fique atento a comunicações suspeitas em nome da escola
- Entre em contato conosco se notar qualquer atividade suspeita

NOSSO COMPROMISSO:
Levamos a proteção dos dados dos alunos muito a sério. Implementamos
melhorias adicionais de segurança para evitar que este tipo de incidente
aconteça novamente.

Para dúvidas, entre em contato com nosso Encarregado de Dados:
privacidade@lexendscholar.com

Atenciosamente,
Marlow Sousa
Encarregado de Dados (DPO)
Lexend Scholar
```

---

## Fase 6: Pós-Incidente

### Postmortem de Segurança (obrigatório para incidentes Críticos e Altos)

Prazo: 5 dias úteis após resolução do incidente

Incluir:
- Linha do tempo completa
- Causa raiz documentada
- Impacto real (número de titulares, dados expostos)
- Eficácia das medidas de contenção
- Lições aprendidas
- Plano de ação com responsáveis e prazos

### Revisão do Programa de Segurança

Após qualquer incidente Crítico ou Alto:
1. Auditoria de todos os controles de segurança relacionados
2. Atualização da Avaliação de Impacto (DPIA)
3. Treinamento da equipe sobre o tipo de incidente
4. Atualização do ROPA com o incidente registrado

---

## Contatos de Emergência — Incidente de Dados

| Papel | Nome | Contato | Disponibilidade |
|---|---|---|---|
| DPO | Marlow Sousa | privacidade@lexendscholar.com / WhatsApp | 24/7 para incidentes Críticos |
| Advogado LGPD | A definir | — | Contratar sob demanda |
| ANPD | — | gov.br/anpd | Comunicação formal |
| Supabase (infraestrutura) | — | support.supabase.com | Plano pago |

---

## Registro de Incidentes

Todos os incidentes (mesmo os menores) devem ser registrados em:
`docs/legal/registros-incidentes/YYYY-MM-DD-descricao.md`

Campos obrigatórios:
- Data de detecção
- Severidade
- Causa raiz
- Dados afetados
- Ações tomadas
- ANPD comunicada? (S/N)
- Titulares comunicados? (S/N)
- Status: Em andamento / Resolvido
