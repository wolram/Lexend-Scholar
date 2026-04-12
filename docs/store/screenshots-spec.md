# Screenshots Spec — App Store Connect

> Issue: LS-174 | Criar screenshots otimizados para conversão (iPhone 6.7" + iPad)

---

## iPhone 6.7" — 1290×2796px

Sequência narrativa de 10 screenshots:

| # | Tela do App | Headline | Cor de Fundo | Posição Headline |
|---|-------------|----------|--------------|-----------------|
| 1 | Dashboard principal | "Sua escola na palma da mão" | #1E3A5F | Topo |
| 2 | Registro de frequência | "Chamada em 3 toques" | #1E3A5F | Topo |
| 3 | Lista de alunos | "Gestão completa de alunos" | #FFFFFF | Topo |
| 4 | Lançamento de notas | "Notas e médias automáticas" | #FFFFFF | Topo |
| 5 | Geração de boletim (PDF preview) | "Boletim em PDF em 1 clique" | #1E3A5F | Base |
| 6 | Cobranças financeiras | "Financeiro sem planilhas" | #FFFFFF | Topo |
| 7 | Relatório de inadimplência | "Controle de inadimplência em tempo real" | #1E3A5F | Base |
| 8 | Comunicados para pais | "Comunicação direta com famílias" | #FFFFFF | Topo |
| 9 | Dashboard iPad (two-pane) | "Feito para diretores" | #1E3A5F | Base |
| 10 | CTA de trial | "14 dias grátis. Sem cartão." | #FFFFFF | Centro |

### Detalhes por Screenshot

**Screenshot 1 — Dashboard Principal**
- Fundo: #1E3A5F
- Headline: "Sua escola na palma da mão" (SF Pro Display Bold, 48pt, #FFFFFF)
- Subtexto: "Tudo que você precisa para gerir sua escola" (SF Pro Text Regular, 28pt, #4A90D9)
- Posição do dispositivo: centralizado com sombra suave
- Mockup: iPhone 15 Pro Space Black

**Screenshot 2 — Registro de Frequência**
- Fundo: #1E3A5F
- Headline: "Chamada em 3 toques" (SF Pro Display Bold, 48pt, #FFFFFF)
- Subtexto: "Selecione a turma → marque os presentes → confirme"
- Destaque visual: seta numerada mostrando o fluxo de 3 passos

**Screenshot 3 — Lista de Alunos**
- Fundo: #FFFFFF
- Headline: "Gestão completa de alunos" (SF Pro Display Bold, 48pt, #1E3A5F)
- Subtexto: "Cadastro, histórico e documentos em um só lugar"
- Badge: "Importação via CSV"

**Screenshot 4 — Lançamento de Notas**
- Fundo: #FFFFFF
- Headline: "Notas e médias automáticas" (SF Pro Display Bold, 48pt, #1E3A5F)
- Subtexto: "Lance notas e a média é calculada na hora"

**Screenshot 5 — Geração de Boletim**
- Fundo: #1E3A5F
- Headline: "Boletim em PDF em 1 clique" (SF Pro Display Bold, 48pt, #FFFFFF)
- Elemento extra: thumbnail do PDF gerado com borda branca
- CTA visual: botão "Gerar PDF" destacado

**Screenshot 6 — Cobranças Financeiras**
- Fundo: #FFFFFF
- Headline: "Financeiro sem planilhas" (SF Pro Display Bold, 48pt, #1E3A5F)
- Subtexto: "Cobranças, pagamentos e relatórios automáticos"

**Screenshot 7 — Relatório de Inadimplência**
- Fundo: #1E3A5F
- Headline: "Controle de inadimplência em tempo real" (SF Pro Display Bold, 44pt, #FFFFFF)
- Elemento: gráfico de barras com dados fictícios verossímeis

**Screenshot 8 — Comunicados**
- Fundo: #FFFFFF
- Headline: "Comunicação direta com famílias" (SF Pro Display Bold, 44pt, #1E3A5F)
- Subtexto: "Push notification + confirmação de leitura"

**Screenshot 9 — Dashboard iPad**
- Fundo: #1E3A5F
- Headline: "Feito para diretores" (SF Pro Display Bold, 48pt, #FFFFFF)
- Mockup: iPad Air com layout two-pane sidebar + conteúdo

**Screenshot 10 — CTA Trial**
- Fundo: #FFFFFF
- Logo Lexend Scholar centralizado
- Headline: "14 dias grátis. Sem cartão." (SF Pro Display Bold, 52pt, #1E3A5F)
- Subtexto: "lexendscholar.com.br"
- Badge: estrelas de avaliação (ex: ★★★★★ "4.8 no App Store")

---

## iPad — 2048×2732px

Versões adaptadas dos mesmos 10 screenshots com layout two-pane:
- Coluna esquerda (40%): sidebar de navegação do app
- Coluna direita (60%): conteúdo principal / tela destacada
- Headlines e subtextos mantidos, tamanhos ampliados em ~20%
- Mockup: iPad Air (5ª geração) com Smart Folio

---

## Diretrizes de Design

### Paleta de Cores (SchoolPalette do app)
| Nome | Hex | Uso |
|------|-----|-----|
| Azul principal | #1E3A5F | Fundo screenshots escuros, headlines claros |
| Accent blue | #4A90D9 | Subtextos em fundos escuros, destaques |
| Fundo claro | #F8FAFC | Background de screenshots claros |
| Branco | #FFFFFF | Texto em fundos escuros, moldura do dispositivo |
| Texto escuro | #1E3A5F | Headlines em fundos claros |

### Tipografia
- **Headlines:** SF Pro Display Bold
- **Subtextos:** SF Pro Text Regular ou Medium
- **Tamanho mínimo de texto:** 28pt (para legibilidade em thumbnail)

### Regras Gerais
- Usar mockups de dispositivo reais (iPhone 15 Pro, iPad Air)
- Dados fictícios mas verossímeis (nomes de alunos genéricos, turma "3º Ano A")
- Sem texto em inglês nos screenshots
- Nenhum logo de terceiros visível
- Exportar em PNG sem compressão
- Testar legibilidade em tamanho de thumbnail (240×430px)
