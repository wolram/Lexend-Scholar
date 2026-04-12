# LS-174 — Screenshots Otimizados para Conversão (iPhone 6.7" + iPad)

## Especificações Técnicas

| Dispositivo | Resolução | Orientação | Quantidade |
|-------------|-----------|-----------|-----------|
| iPhone 6.7" (iPhone 15 Pro Max) | 1290 × 2796 px | Retrato | 10 screenshots |
| iPad Pro 12.9" | 2048 × 2732 px | Retrato | 10 screenshots |

- Formato: PNG ou JPEG (sem alpha para JPEG)
- Espaço de cor: sRGB
- Profundidade: 8-bit
- Sem bordas, sem logos de app sobrepostos

---

## Sequência Narrativa (Ordem dos Screenshots)

### Screenshot 1 — Hero / Proposta de Valor
**Tela:** Dashboard principal (visão geral)
**Título:** "Sua escola na palma da mão"
**Subtítulo:** "Gestão completa para escolas privadas"
**Elementos visuais:** Dashboard com cards de resumo — alunos ativos, frequência do dia, pendências financeiras
**Cor de fundo:** Azul institucional SchoolPalette (#1E3A5F)

### Screenshot 2 — Cadastro de Alunos
**Tela:** Lista de alunos + perfil de aluno
**Título:** "Cadastro rápido e completo"
**Subtítulo:** "Ficha do aluno com histórico integrado"
**Elementos visuais:** Lista com avatar, nome, turma, status; detalhe do perfil com foto
**Cor de fundo:** Branco com card em azul claro

### Screenshot 3 — Controle de Frequência
**Tela:** Chamada digital com swipe para marcar presença
**Título:** "Frequência em segundos"
**Subtítulo:** "Chamada digital com um toque"
**Elementos visuais:** Lista de alunos com toggle Presente/Ausente, barra de progresso da turma
**Cor de fundo:** Verde suave (#E8F5E9)

### Screenshot 4 — Boletim Digital
**Tela:** Boletim gerado com notas por disciplina
**Título:** "Boletim digital instantâneo"
**Subtítulo:** "Gerado automaticamente, compartilhado via WhatsApp"
**Elementos visuais:** Boletim formatado com notas, médias, conceitos e gráfico de evolução
**Cor de fundo:** Branco com acento azul

### Screenshot 5 — Lançamento de Notas
**Tela:** Grade de notas por turma e bimestre
**Título:** "Notas lançadas sem planilha"
**Subtítulo:** "Importação via CSV ou digitação direta"
**Elementos visuais:** Tabela de notas com células editáveis, indicador de alunos em risco
**Cor de fundo:** Azul escuro (#1E3A5F)

### Screenshot 6 — Financeiro / Mensalidades
**Tela:** Painel de cobranças e inadimplência
**Título:** "Mensalidades sob controle"
**Subtítulo:** "Cobranças automáticas e relatório de inadimplência"
**Elementos visuais:** Cards de recebidos/pendentes, lista de inadimplentes com valor, botão de envio de cobrança
**Cor de fundo:** Laranja suave (#FFF3E0)

### Screenshot 7 — Comunicação com Responsáveis
**Tela:** Feed de comunicados + chat com responsável
**Título:** "Comunicação direta com as famílias"
**Subtítulo:** "Avisos, notificações e mensagens em um só lugar"
**Elementos visuais:** Feed de notícias com foto, badge de leitura, campo de resposta
**Cor de fundo:** Branco com ícones coloridos

### Screenshot 8 — Agenda / Calendário Escolar
**Tela:** Calendário mensal com eventos marcados
**Título:** "Agenda escolar integrada"
**Subtítulo:** "Eventos, provas e reuniões para toda a comunidade"
**Elementos visuais:** Calendário com dots coloridos por categoria, lista do dia
**Cor de fundo:** Roxo suave (#F3E5F5)

### Screenshot 9 — Relatórios Pedagógicos
**Tela:** Dashboard de relatórios com gráficos
**Título:** "Decisões baseadas em dados"
**Subtítulo:** "Relatórios automáticos de frequência e desempenho"
**Elementos visuais:** Gráfico de barras de desempenho por turma, mapa de calor de frequência
**Cor de fundo:** Azul escuro (#1E3A5F)

### Screenshot 10 — Multi-perfil (Diretor / Professor / Secretaria)
**Tela:** Tela de seleção de perfil no login
**Título:** "Para toda a equipe escolar"
**Subtítulo:** "Perfis para diretor, professor e secretaria"
**Elementos visuais:** 3 cards de perfil com ícones, nome e lista de permissões resumida
**Cor de fundo:** Gradiente azul para branco

---

## Diretrizes de Design

### Tipografia
- Título: SF Pro Display Bold, 52pt, branco ou azul escuro
- Subtítulo: SF Pro Text Regular, 36pt, cinza escuro (#424242)
- Fonte do app nas telas: Lexend Regular (fonte da marca)

### Paleta de Cores (SchoolPalette)
| Cor | Hex | Uso |
|-----|-----|-----|
| Azul Principal | #1E3A5F | Fundo hero, CTAs |
| Azul Claro | #4A90D9 | Destaques, ícones |
| Verde Sucesso | #43A047 | Frequência, aprovação |
| Laranja Alerta | #FB8C00 | Financeiro, pendências |
| Cinza Texto | #424242 | Corpo de texto |
| Branco | #FFFFFF | Fundo padrão |

### Regras de Composição
1. Device mockup: iPhone 15 Pro Max (titânio natural) e iPad Pro (espaço cinza)
2. Sem status bar com horário e bateria reais — usar mock com 9:41 AM e bateria cheia
3. Dados fictícios mas realistas (nomes brasileiros, valores em R$, datas plausíveis)
4. Texto de título fora da tela do device (zona superior ou inferior)
5. Margem mínima: 80px de cada lado para iPhone, 120px para iPad

---

## Checklist de Produção

- [ ] Criar mockups no Figma usando template de screenshot 1290×2796
- [ ] Exportar telas do app em resolução 3x via Simulator
- [ ] Inserir device frame com Shadow sutil (blur 24, opacity 30%)
- [ ] Adicionar texto de título e subtítulo em cada screenshot
- [ ] Exportar PNG sem compressão
- [ ] Validar dimensões exatas antes do upload
- [ ] Fazer upload no App Store Connect → App Store → Screenshots
- [ ] Testar pré-visualização nos diferentes tamanhos de tela

---

## Ferramentas Recomendadas

| Ferramenta | Uso |
|-----------|-----|
| Figma | Design dos frames e composição |
| Xcode Simulator | Captura de tela em alta resolução |
| ScreenshotMaker | Templates prontos com device frames |
| App Store Connect | Upload e pré-visualização |

---

## Referências

- [App Store Screenshot Specs — Apple](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications/)
- [Title & Keywords — LS-172](./LS-172-titulo-subtitulo-app-store.md)
