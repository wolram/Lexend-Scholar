# LS-176 — Preview Video do App (15–30 segundos)

## Especificações Técnicas — App Store

| Parâmetro | Valor |
|-----------|-------|
| Duração | 15–30 segundos |
| Resolução iPhone 6.7" | 886 × 1920 px (9:19.5) |
| Resolução iPad 12.9" | 1200 × 1600 px |
| Frame rate | 30 fps |
| Formato | MOV ou MP4 (H.264 ou HEVC) |
| Bitrate máximo | 500 Mbps |
| Áudio | Nenhum (política App Store: sem música de fundo) |
| Legendas | Sim — obrigatório (accessibility + política) |

> **Importante:** A App Store reproduz o preview sem som por padrão. Todo conteúdo deve ser comunicado visualmente com legendas em português.

---

## Roteiro — 25 segundos

### Estrutura de Cenas

```
[00:00–00:03] ABERTURA (3s)
Tela preta → Logo Lexend Scholar animado aparece no centro
Legenda: "Gestão escolar simples e eficiente"

[00:03–00:08] CENA 1 — Login e Dashboard (5s)
Screen recording: abertura do app → tela de login → dashboard principal
Mostrar: cards de resumo (alunos, frequência, financeiro)
Legenda: "Tudo que sua escola precisa em um só lugar"

[00:08–00:13] CENA 2 — Frequência Digital (5s)
Screen recording: abrir turma → chamada → marcar presença com toque
Mostrar: swipe rápido, confirmação visual, barra de progresso
Legenda: "Frequência registrada em segundos"

[00:13–00:18] CENA 3 — Lançamento de Notas e Boletim (5s)
Screen recording: lançar nota → visualizar boletim gerado
Mostrar: grade de notas → tap em "Gerar Boletim" → PDF animado
Legenda: "Boletim digital gerado automaticamente"

[00:18–00:23] CENA 4 — Comunicação com Famílias (5s)
Screen recording: criar aviso → notificação push na tela do responsável
Mostrar: feed de comunicados, confirmação de leitura
Legenda: "Comunicação direta com os responsáveis"

[00:23–00:25] FECHAMENTO (2s)
Logo Lexend Scholar + tagline
Legenda: "Lexend Scholar — Transforme sua escola"
```

---

## Diretrizes de Produção

### Captura de Tela
1. Usar iPhone 15 Pro Max físico ou Simulator em resolução máxima
2. Gravar com QuickTime Player (Arquivo → Nova Gravação de Tela do iPhone)
3. Ativar modo "Não Perturbe" antes de gravar
4. Status bar: 9:41 AM, sinal cheio, bateria 100%
5. Usar dados realistas de demonstração (escola fictícia "Colégio São Lucas")

### Edição
1. Ferramenta: DaVinci Resolve (gratuito) ou Final Cut Pro
2. Transições: corte seco ou fade rápido (0.2s) — sem efeitos elaborados
3. Legendas: fonte SF Pro Display Bold, branco com sombra leve, posição inferior
4. Zoom suave (Ken Burns) nas telas para destacar ações importantes
5. Sem música, sem narração, sem sons de notificação

### Legendas (SRT)
```srt
1
00:00:00,000 --> 00:00:03,000
Gestão escolar simples e eficiente

2
00:00:03,000 --> 00:00:08,000
Tudo que sua escola precisa em um só lugar

3
00:00:08,000 --> 00:00:13,000
Frequência registrada em segundos

4
00:00:13,000 --> 00:00:18,000
Boletim digital gerado automaticamente

5
00:00:18,000 --> 00:00:23,000
Comunicação direta com os responsáveis

6
00:00:23,000 --> 00:00:25,000
Lexend Scholar — Transforme sua escola
```

---

## Fluxo de Aprovação

| Etapa | Responsável | Prazo |
|-------|-------------|-------|
| Gravação das telas | Desenvolvedor iOS | D+0 |
| Edição do vídeo | Designer / Marketing | D+2 |
| Revisão interna | Product Owner | D+3 |
| Upload no App Store Connect | DevOps / Marketing | D+4 |
| Review pela Apple | Apple (automático) | D+4 a D+5 |

---

## Checklist de Envio

- [ ] Vídeo exportado em resolução 886×1920 px
- [ ] Duração entre 15–30 segundos (alvo: 25s)
- [ ] Sem áudio (ou áudio mudo)
- [ ] Legendas visíveis e legíveis
- [ ] Dados fictícios sem informações pessoais reais
- [ ] Upload via App Store Connect → App Preview
- [ ] Thumbnail do preview selecionado manualmente (frame mais atraente)

---

## Referências

- [App Preview Specifications — Apple](https://developer.apple.com/help/app-store-connect/reference/app-preview-specifications/)
- [App Store Review Guidelines 2.3.7](https://developer.apple.com/app-store/review/guidelines/#2.3.7)
- [Screenshots — LS-174](./LS-174-screenshots-app-store.md)
