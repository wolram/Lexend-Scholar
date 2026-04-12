# Preview Video — Roteiro (25 segundos)

> Issue: LS-176 | Produzir preview video do app (15-30 segundos)

---

## Roteiro de Cenas

| Tempo | Cena | Tela do App | Narração / Legenda |
|-------|------|-------------|-------------------|
| 0–3s | Logo em fade in | Tela azul sólida (#1E3A5F) com logo Lexend Scholar centralizado | — |
| 3–7s | Login rápido | Tela de login → toque no botão "Entrar" → dashboard carregando | "Acesse em segundos" |
| 7–12s | Frequência | Selecionar turma → lista de alunos → marcar 3 presenças com toque → confirmar | "Frequência em 3 toques" |
| 12–17s | Boletim | Campo de nota preenchido → botão "Gerar Boletim" → PDF abrindo | "Boletim gerado automaticamente" |
| 17–22s | Dashboard | Cards de resumo com números reais: alunos, presença %, inadimplência | "Sua escola sob controle" |
| 22–25s | CTA | Tela branca com logo + URL lexendscholar.com.br | "14 dias grátis" |

---

## Detalhes de Direção por Cena

### Cena 1 — Logo (0–3s)
- Fade in do logo de 0 a 1s
- Manter estático de 1s a 2.5s
- Fade out suave para próxima cena
- Sem narração, sem legenda

### Cena 2 — Login (3–7s)
- Gravação em tela real do iPhone (não simulador)
- Touch highlights ativados (Configurações → Acessibilidade)
- Legenda: "Acesse em segundos" — posição: base da tela, fundo azul translúcido #1E3A5F com 80% de opacidade

### Cena 3 — Frequência (7–12s)
- Mostrar claramente os 3 toques numerados com anotação visual (círculos 1, 2, 3)
- Velocidade normal — não acelerar
- Legenda: "Frequência em 3 toques"

### Cena 4 — Boletim (12–17s)
- Digitar uma nota (ex: 8.5) → ver média calculada automaticamente → tocar "Gerar PDF" → PDF abrindo em preview
- Pode usar leve speed-up na abertura do PDF (1.5x)
- Legenda: "Boletim gerado automaticamente"

### Cena 5 — Dashboard (17–22s)
- Scroll suave pelo dashboard mostrando os cards
- Números reais e verossímeis: "127 alunos", "94% de presença", "R$ 3.400 pendente"
- Legenda: "Sua escola sob controle"

### Cena 6 — CTA (22–25s)
- Tela branca limpa
- Logo centralizado (versão escura do logo)
- URL: lexendscholar.com.br em cinza #6B7280
- Headline: "14 dias grátis" em #1E3A5F, SF Pro Display Bold, grande
- Fade out para preto

---

## Especificações Técnicas

| Campo | Especificação |
|-------|--------------|
| Resolução iPhone | 1080×1920px (9:16 portrait) |
| Resolução iPad | 1080×1080px (1:1, compatível) |
| Codec | H.264 (AVC), perfil High |
| Bitrate mínimo | 10 Mbps |
| Tamanho máximo | 500 MB |
| Duração | 15–30 segundos (este vídeo: 25s) |
| Frame rate | 60fps |
| Áudio | Opcional — sem narração em voz, apenas trilha instrumental suave |
| Legendas | **Obrigatórias** para acessibilidade — texto em português |
| Logos de terceiros | Proibido — nenhum logo de app ou serviço externo visível |
| Idioma | Português (Brasil) |

---

## Ferramentas Sugeridas

### Opção 1 — ScreenFlow (Mac) — Recomendada
- Grave diretamente do iPhone via cabo USB
- Edição frame a frame
- Export direto para H.264 com configurações do App Store
- Tutorial: screenflow.com/tutorials

### Opção 2 — Screen Recording nativo iOS + iMovie
1. Ative a gravação de tela no iPhone (Centro de Controle)
2. Grave cada cena separadamente
3. Monte no iMovie (Mac ou iPad)
4. Export: Arquivo → 1080p → melhor qualidade
5. Converta para H.264 com HandBrake se necessário

### Opção 3 — Rotato ou Rottenwood (mockup animado)
- Para criar o vídeo sem device físico
- Importar screenshots e animar transições
- Ideal para cenas de logo e CTA

---

## Checklist de Aprovação

- [ ] Duração entre 15s e 30s
- [ ] Resolução 1080×1920px mínima
- [ ] Legendas em português presentes em todas as cenas com texto
- [ ] Nenhum logo de terceiros visível
- [ ] Nenhuma voz em off (ou voz aprovada pela equipe)
- [ ] Dados fictícios verossímeis (sem PII real)
- [ ] Arquivo final em H.264, máx. 500MB
- [ ] Testado em preview do App Store Connect antes de submeter
