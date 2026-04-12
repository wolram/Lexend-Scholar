# Estratégia de Gestão de Reviews — App Store

> Issue: LS-178 | Criar estratégia de gestão de avaliações e reviews

---

## Trigger In-App — SKStoreReviewController (iOS)

```swift
import StoreKit

// Solicitar review após evento de sucesso
func requestReviewIfAppropriate() {
    let reviewCount = UserDefaults.standard.integer(forKey: "successfulActions")
    if reviewCount >= 5 && !UserDefaults.standard.bool(forKey: "reviewRequested") {
        SKStoreReviewController.requestReview()
        UserDefaults.standard.set(true, forKey: "reviewRequested")
    }
}
```

### Gatilhos de Solicitação
Incrementar `successfulActions` após cada um dos eventos abaixo:

| Evento | Peso | Descrição |
|--------|------|-----------|
| Boletim gerado | +2 | Usuário gerou e visualizou um PDF de boletim |
| 5° login | +1 | Usuário faz o 5° login na sessão atual do app |
| Primeira importação de alunos | +2 | Upload de CSV concluído com sucesso |
| Frequência registrada por 7 dias seguidos | +2 | Streak de uso consistente |
| Primeiro pagamento recebido | +1 | Webhook de pagamento confirmado via Stripe |

> Nota: Respeitar o limite da Apple — no máximo 3 solicitações por período de 365 dias. Resetar `reviewRequested` a cada nova versão major do app.

---

## Templates de Resposta (em Português)

### Template 1 — Review 5 Estrelas

> **Contexto:** Usuário elogiou o app com nota máxima.

```
Obrigado pelo feedback incrível! 🎓

Fico muito feliz que o [funcionalidade elogiada] esteja ajudando sua escola no dia a dia. 
É exatamente para isso que construímos o Lexend Scholar.

Se você gerencia uma rede de escolas ou quer conhecer nossos planos Pro e Enterprise 
com suporte dedicado e recursos avançados, entre em contato: contato@lexendscholar.com.br

Continue fazendo o ótimo trabalho na educação! 🙌
— Equipe Lexend Scholar
```

---

### Template 2 — Review 4 Estrelas

> **Contexto:** Usuário gostou mas não deu nota máxima.

```
Muito obrigado pela avaliação e pelo carinho com o Lexend Scholar!

Sua opinião é muito importante para nós. Ficamos curiosos: o que poderia ter sido diferente 
para você nos dar aquela quinta estrela? 😊

Se tiver alguma sugestão específica, adoraríamos ouvir em suporte@lexendscholar.com.br 
ou pelo nosso chat no app. Sua ideia pode virar a próxima funcionalidade!

— Equipe Lexend Scholar
```

---

### Template 3 — Review 3 Estrelas

> **Contexto:** Avaliação mediana, usuário provavelmente tem pontos específicos de melhoria.

```
Obrigado por nos avaliar e usar o Lexend Scholar!

Percebemos que sua experiência ainda não foi a que gostaríamos de proporcionar. 
Poderia nos contar mais sobre o que não funcionou bem? Queremos entender e resolver.

Entre em contato direto conosco: suporte@lexendscholar.com.br
Respondemos em até 24 horas úteis.

Estamos comprometidos em melhorar e sua experiência é nossa prioridade.
— Equipe Lexend Scholar
```

---

### Template 4 — Review Negativo com Bug Específico

> **Contexto:** Usuário relatou um bug concreto (ex: "o app trava ao gerar boletim").

```
Olá! Muito obrigado por relatar esse problema — lamentamos muito pela experiência ruim.

Identificamos o problema que você descreveu e já está na nossa lista de correções 
para a próxima versão do app (previsão: [prazo da próxima versão]).

Para que possamos ajudá-lo antes da atualização, entre em contato diretamente:
📧 suporte@lexendscholar.com.br
💬 Chat no app (segunda a sexta, 8h–18h)

Sua escola não pode parar — vamos resolver isso juntos.
— Equipe Lexend Scholar
```

---

### Template 5 — Review Negativo sem Motivo Claro

> **Contexto:** Nota baixa sem explicação ou comentário vago.

```
Olá! Obrigado por usar o Lexend Scholar e por deixar sua avaliação.

Ficamos tristes ao ver que sua experiência não foi boa e gostaríamos de entender melhor 
o que aconteceu para podermos ajudar.

Entre em contato conosco: suporte@lexendscholar.com.br
Também oferecemos uma sessão de onboarding gratuita de 30 minutos para 
ajudar sua equipe a aproveitar ao máximo todas as funcionalidades do app.

Basta agendar em: lexendscholar.com.br/onboarding
— Equipe Lexend Scholar
```

---

## KPIs e Metas

| Métrica | Meta | Como Medir |
|---------|------|-----------|
| Rating médio | > 4.5 estrelas | App Store Connect → Ratings and Reviews |
| Tempo de resposta | 100% dos reviews em < 24h | Monitoramento diário no App Store Connect |
| Reviews nos primeiros 90 dias | ≥ 50 reviews | App Store Connect → Reviews |
| % de reviews respondidos | 100% (1 a 5 estrelas) | App Store Connect |
| Conversão de 3★ para 5★ após resposta | > 20% | Acompanhar resposta manual |

---

## Processo Operacional

### Monitoramento Diário
1. Abrir App Store Connect → Ratings and Reviews às 9h
2. Responder todos os reviews não respondidos
3. Prioridade: 1★ e 2★ primeiro, depois 3★, depois 4★ e 5★
4. Registrar reviews com bugs em issue no Linear (label: `bug`, `from-review`)

### Processo de Escalada
- **Bug crítico (P0/P1):** acionar engenharia imediatamente via Linear
- **Solicitação de funcionalidade:** criar issue com label `feature-request` no Linear
- **Possível cliente enterprise:** encaminhar para time comercial

### Revisão Mensal
- Analisar temas recorrentes nos reviews
- Identificar funcionalidades mais elogiadas → destacar nos screenshots e descrição
- Identificar fricções recorrentes → criar sprint de UX/produto
