# Como emitir declarações escolares — Guia para Secretaria

**Perfil**: Secretaria
**Tempo estimado**: 5 minutos
**Última atualização**: Abril 2026

---

## Visão Geral

O Lexend Scholar permite emitir declarações escolares em PDF com assinatura digital em poucos cliques. Os documentos têm validade jurídica e incluem QR Code de autenticação.

**Declarações disponíveis:**
- Declaração de Matrícula
- Declaração de Frequência
- Declaração de Conclusão de Série
- Histórico Escolar Parcial
- Atestado de Escolaridade

---

## Passo a Passo: Emitir Declaração de Matrícula

### Passo 1: Buscar o aluno

**No app iOS:**
1. Toque em **"Secretaria"** → **"Alunos"**
2. Use a barra de busca e digite o nome do aluno
3. Toque no nome do aluno para abrir o perfil

**Na versão web:**
1. Acesse **Secretaria → Alunos**
2. Digite o nome na busca ou use os filtros (turma, série, turno)

*[Screenshot: Tela de listagem de alunos com campo de busca ativo, mostrando resultado "Ana Paula Ferreira — 3A — Matemática da Manhã"]*

---

### Passo 2: Acessar "Documentos" do aluno

1. No perfil do aluno, role até a seção **"Documentos"**
2. Toque em **"Emitir Declaração"**
3. Selecione o tipo de declaração no menu:
   - Declaração de Matrícula
   - Declaração de Frequência
   - Atestado de Escolaridade
   - Histórico Escolar Parcial

*[Screenshot: Perfil do aluno "Ana Paula Ferreira" com seção "Documentos" visível, menu de declarações aberto mostrando os tipos disponíveis]*

---

### Passo 3: Configurar a declaração

Para **Declaração de Matrícula**, configure:

| Opção | Padrão | Observação |
|---|---|---|
| Finalidade | "A quem possa interessar" | Pode ser personalizado (ex: "Para fins de INSS") |
| Data de emissão | Hoje | Pode retroagir em até 30 dias |
| Incluir foto do aluno | Sim | Desmarque se a escola não tiver foto cadastrada |
| Assinatura | Diretor (nome configurado) | Puxado das configurações da escola |
| Idioma | Português (BR) | Inglês disponível no plano Pro+ |

*[Screenshot: Formulário de configuração da declaração com campos preenchidos e preview do documento ao lado direito]*

Para **Declaração de Frequência**, adicione:
- **Período**: Data de início e fim (padrão: ano letivo atual)
- **Percentual de frequência**: Calculado automaticamente pelo sistema
- **Observações**: Campo livre para notas adicionais

---

### Passo 4: Pré-visualizar o documento

1. Toque em **"Pré-visualizar"**
2. O PDF aparece em tela cheia com todos os dados preenchidos
3. Verifique: nome do aluno, série, turma, datas e assinatura
4. Se houver erro, feche o preview, corrija e pré-visualize novamente

*[Screenshot: Preview do PDF da Declaração de Matrícula, mostrando o cabeçalho com logo da escola, dados do aluno, texto da declaração e campo de assinatura e carimbo]*

---

### Passo 5: Emitir e entregar

**Opções de entrega:**

**A) Enviar por email para o responsável:**
1. Toque em **"Enviar por Email"**
2. O email do responsável principal já aparece preenchido
3. Adicione outros emails se necessário (ex: RH da empresa)
4. Toque em **"Enviar"** — o PDF é enviado em segundos

*[Screenshot: Modal de envio de email com campo "Para:" preenchido com o email do responsável e campo "Mensagem" com texto padrão da escola]*

**B) Baixar o PDF:**
1. Toque em **"Baixar PDF"**
2. O arquivo é salvo na pasta de Downloads do dispositivo
3. Imprima normalmente ou envie por WhatsApp

**C) Imprimir diretamente:**
1. Toque em **"Imprimir"**
2. Selecione a impressora (AirPrint no iOS)
3. Configure cópias e toque em "Imprimir"

---

## Autenticação por QR Code

Todos os documentos emitidos pelo Lexend Scholar incluem um **QR Code de autenticação** no rodapé. Isso permite que qualquer pessoa (empresa, outra escola, órgão público) verifique a autenticidade do documento digitalmente, sem precisar ligar para a escola.

Como funciona:
1. O documento inclui um código único (ex: `LS-DOC-2026-00847`)
2. Há um QR Code que aponta para `verificar.lexendscholar.com/LS-DOC-2026-00847`
3. A página de verificação confirma: escola, aluno, tipo de documento, data de emissão e validade

*[Screenshot: Rodapé do PDF da declaração mostrando QR Code e código de verificação, com texto "Verifique a autenticidade em verificar.lexendscholar.com"]*

---

## Histórico de Documentos Emitidos

Todos os documentos emitidos ficam registrados no histórico do aluno:

1. Acesse o perfil do aluno
2. Vá em **"Documentos" → "Histórico de Emissões"**
3. Você verá: tipo, data de emissão, quem emitiu, e se foi enviado por email

*[Screenshot: Lista de documentos emitidos para "Ana Paula Ferreira" com datas, tipos e ícones de download]*

Isso garante rastreabilidade: você sabe exatamente quantas declarações foram emitidas, para quem e quando.

---

## Emissão em Massa

Precisa emitir declarações para toda uma turma de uma vez?

1. Em **"Turmas"**, selecione a turma
2. Toque em **"Ações em massa"** → **"Emitir declarações"**
3. Selecione o tipo de declaração
4. Escolha: Baixar um ZIP com todos os PDFs, ou Enviar por email para todos os responsáveis
5. O sistema processa e notifica quando concluir (pode levar alguns minutos para turmas grandes)

*[Screenshot: Modal de ações em massa com a opção "Emitir Declaração de Matrícula para 35 alunos" selecionada e botões de download e envio por email]*

---

## Erros Comuns e Soluções

| Problema | Causa | Solução |
|---|---|---|
| "Foto do aluno não disponível" | Foto não cadastrada | Adicione a foto no perfil do aluno antes de emitir |
| Assinatura em branco | Diretor não configurado | Acesse Configurações → Escola → Responsável Legal |
| "Frequência insuficiente para calcular" | Poucos lançamentos | Garanta que a frequência do período está lançada |
| QR Code sem link válido | Documento emitido offline | Emita novamente com conexão à internet para ativar a verificação |

---

## Perguntas Frequentes

**A declaração tem validade jurídica sem assinatura física?**
Sim. Os documentos emitidos pelo Lexend Scholar têm validade jurídica através da assinatura digital do responsável legal cadastrado e do QR Code de autenticação, conforme a Lei 14.063/2020 (assinaturas eletrônicas).

**Posso personalizar o modelo da declaração com o cabeçalho da escola?**
Sim. Acesse **Configurações → Escola → Personalização de Documentos** para carregar o logo, definir cores e configurar o texto padrão das declarações.

**O responsável pode solicitar a declaração direto pelo app dele?**
Sim, no plano Pro e Enterprise. O responsável acessa o app, vai em "Documentos" e solicita a declaração. A secretaria recebe a solicitação e aprova com um toque.

---

**Precisa de ajuda?** Chat de suporte disponível no canto inferior direito ou suporte@lexendscholar.com.
