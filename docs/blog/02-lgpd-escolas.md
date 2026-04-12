# LGPD nas escolas: o que seu sistema de gestão precisa ter

**Categoria**: Conformidade e Segurança
**Palavras-chave**: LGPD escolas, lei geral de proteção de dados educação, dados alunos LGPD, conformidade LGPD escola, proteção dados crianças escola
**Meta description**: A LGPD se aplica às escolas e as sanções podem chegar a R$50 milhões. Veja o que seu sistema de gestão escolar precisa ter para estar em conformidade.

---

A Lei Geral de Proteção de Dados (LGPD) entrou em vigor em 2020 e, desde 2021, a ANPD (Autoridade Nacional de Proteção de Dados) já aplicou multas e advertências a organizações que descumprem a lei. Escolas guardam dados sensíveis de menores de idade — e isso coloca a conformidade com a LGPD no topo das prioridades de qualquer gestor escolar responsável.

## Por que escolas são especialmente sensíveis à LGPD

Escolas coletam e processam uma quantidade enorme de dados pessoais: nome completo, CPF, RG, endereço, dados de saúde (alergias, deficiências, medicamentos), informações familiares, histórico acadêmico, registros disciplinares e, cada vez mais, biometria e localização. Quando esses dados pertencem a crianças e adolescentes, a LGPD exige proteção reforçada (Art. 14).

O não cumprimento pode resultar em:
- Advertências públicas que afetam a reputação da escola
- Multas de até 2% do faturamento anual (máximo R$50 milhões por infração)
- Suspensão do banco de dados — o que na prática inviabilizaria as operações
- Ações judiciais de responsáveis que se sentirem prejudicados

## O que o sistema de gestão precisa ter

### 1. Criptografia de dados em repouso e em trânsito

Todos os dados armazenados no sistema devem ser criptografados (AES-256 ou superior). A comunicação entre dispositivos e servidores deve usar TLS 1.2 ou superior. Peça ao fornecedor comprovação técnica desses controles.

### 2. Controle de acesso por perfil (RBAC)

O professor de matemática não precisa ver o histórico financeiro do aluno. O responsável financeiro não deve acessar registros disciplinares. Um sistema adequado implementa controle de acesso granular, onde cada usuário vê apenas o que precisa para seu trabalho.

### 3. Finalidade de uso documentada para cada dado

A LGPD exige que cada dado seja coletado com uma finalidade específica e legítima. O sistema deve documentar automaticamente por que cada informação é coletada. Exemplo: "CPF do aluno → finalidade: emissão de documentos escolares e obrigações fiscais".

### 4. Consentimento documentado dos responsáveis

Para dados de menores, o consentimento deve ser dado pelos pais ou responsáveis legais. O sistema precisa armazenar esse consentimento com data, hora e IP, de forma que possa ser apresentado como prova em caso de questionamento.

### 5. Direito de acesso e portabilidade dos dados (DSAR)

A LGPD garante que titulares (ou responsáveis, no caso de menores) podem solicitar acesso a todos os dados que a escola possui sobre eles. O sistema precisa gerar esse relatório de forma simples e rápida. Prazo legal para resposta: 15 dias.

### 6. Direito de exclusão (direito ao esquecimento)

Quando um aluno se transfere ou se forma, os responsáveis podem solicitar a exclusão dos dados. O sistema precisa implementar essa funcionalidade, mantendo apenas o mínimo exigido por obrigação legal (ex: histórico escolar conforme LDB).

### 7. Registro de atividades de tratamento (ROPA)

O Art. 37 da LGPD exige um mapeamento de todas as atividades de tratamento de dados. O sistema deve fornecer relatórios que auxiliem na elaboração e manutenção do ROPA.

### 8. Notificação de incidentes

Em caso de vazamento de dados, a ANPD deve ser notificada em até 72 horas. O sistema precisa ter monitoramento de acessos suspeitos e alertas de segurança.

### 9. Política de retenção de dados

Dados não podem ser guardados por mais tempo do que o necessário. O sistema precisa implementar políticas de retenção automáticas: dados de ex-alunos podem ser anonimizados após X anos, salvo obrigações legais específicas.

### 10. Dados de saúde tratados como sensíveis

Informações sobre alergias, condições médicas, deficiências e medicamentos são dados sensíveis (Art. 11 da LGPD) e exigem proteção adicional. O sistema deve identificar e tratar esses campos com controles reforçados.

## Checklist de conformidade para gestores

Aplique este checklist ao avaliar seu sistema atual ou um novo:

- [ ] Criptografia em repouso (AES-256 ou superior)
- [ ] Comunicação criptografada (TLS 1.2+)
- [ ] Controle de acesso por perfil (RBAC)
- [ ] Consentimento de titulares armazenado com evidências
- [ ] Processo para atender solicitações DSAR em até 15 dias
- [ ] Processo para exclusão de dados de ex-alunos
- [ ] Política de retenção de dados implementada
- [ ] Log de auditoria de acessos e alterações
- [ ] DPO (Encarregado de Dados) designado
- [ ] Contrato de processamento de dados (DPA) com o fornecedor
- [ ] Plano de resposta a incidentes de dados documentado
- [ ] Funcionários treinados em proteção de dados

## Perguntas que você deve fazer ao seu fornecedor de sistema

1. "Onde fisicamente os dados dos meus alunos estão armazenados?" (Deve ser no Brasil ou em país com adequação reconhecida pela ANPD)
2. "Você assina um DPA (Data Processing Agreement) comigo?" (Obrigatório pela LGPD)
3. "Como você notifica em caso de incidente de segurança?"
4. "Quais certificações de segurança vocês possuem?" (ISO 27001, SOC 2 são bons indicadores)
5. "Tenho acesso a logs de auditoria de quem acessou os dados dos meus alunos?"

## A responsabilidade é da escola, não só do fornecedor

Um ponto crucial: mesmo que o sistema de gestão seja o controlador técnico dos dados, a escola é a **controladora** perante a LGPD. Isso significa que a escola é responsável por garantir que o fornecedor também está em conformidade. Por isso, o contrato com o fornecedor de software escolar deve incluir cláusulas de proteção de dados.

---

*O Lexend Scholar foi desenvolvido com conformidade LGPD desde o primeiro dia: dados armazenados no Brasil, criptografia ponta a ponta, DPA incluído em todos os contratos e suporte para atendimento a DSARs. Saiba mais em lexendscholar.com/lgpd.*
