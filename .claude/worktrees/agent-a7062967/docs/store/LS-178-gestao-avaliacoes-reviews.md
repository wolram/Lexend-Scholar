# LS-178 — Estratégia de Gestão de Avaliações e Reviews

## Objetivo

Manter rating médio acima de 4.5 estrelas na App Store e Google Play após 30 dias de lançamento,
por meio de prompt inteligente de avaliação, resposta rápida a reviews negativos e monitoramento semanal.

---

## 1. Prompt de Avaliação In-App

### Quando Solicitar (Triggeres de Sucesso)

Usar `SKStoreReviewRequestAPI` (iOS) e `ReviewManager` (Android) apenas após ações de sucesso:

| Gatilho | Ação do Usuário | Delay |
|---------|----------------|-------|
| Boletim gerado | Toque em "Gerar Boletim" → PDF exibido | 2 segundos |
| Frequência completa | Chamada encerrada com 100% da turma | Imediato |
| Matrícula concluída | Confirmação de matrícula de aluno | 3 segundos |
| Mensalidade recebida | Pagamento registrado como "Recebido" | 2 segundos |
| Primeiro acesso completo | Usuário completa onboarding (5 passos) | 1 dia após |

### Regras de Limitação (iOS SKStoreReviewRequestAPI)
- Máximo 3 solicitações por período de 365 dias (limite Apple)
- Nunca solicitar após evento negativo (erro, timeout, reclamação)
- Nunca solicitar na primeira sessão do usuário
- Aguardar mínimo 3 dias após instalação antes do primeiro prompt
- Respeitar decisão: se usuário não avaliou, aguardar 60 dias para novo prompt

### Implementação iOS (SwiftUI)

```swift
import StoreKit

func requestReviewAfterSuccess(triggerEvent: ReviewTrigger) {
    let defaults = UserDefaults.standard
    let lastRequestDate = defaults.object(forKey: "lastReviewRequestDate") as? Date
    let installDate = defaults.object(forKey: "installDate") as? Date ?? Date()
    
    // Aguardar 3 dias após instalação
    guard Date().timeIntervalSince(installDate) > 3 * 24 * 3600 else { return }
    
    // Aguardar 60 dias desde o último pedido
    if let lastDate = lastRequestDate,
       Date().timeIntervalSince(lastDate) < 60 * 24 * 3600 { return }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(triggerEvent.delay)) {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
            defaults.set(Date(), forKey: "lastReviewRequestDate")
        }
    }
}

enum ReviewTrigger {
    case boletimGerado, frequenciaCompleta, matriculaConcluida
    
    var delay: Int {
        switch self {
        case .boletimGerado: return 2
        case .frequenciaCompleta: return 0
        case .matriculaConcluida: return 3
        }
    }
}
```

---

## 2. Templates de Resposta para Reviews

### Reviews 1–2 Estrelas (Crítico)

**Template Negativo — Bug/Erro:**
```
Olá, [Nome]! Lamentamos muito pela experiência. Esse tipo de problema não reflete o padrão 
que queremos entregar. Nossa equipe já foi notificada e estamos investigando. 
Por favor, envie os detalhes para suporte@lexendscholar.com.br para que possamos resolver 
rapidamente e enviar uma atualização. Obrigado pela honestidade!
```

**Template Negativo — Funcionalidade Ausente:**
```
Olá, [Nome]! Obrigado pelo feedback — funcionalidades como [X] estão no nosso roadmap. 
Se puder compartilhar mais detalhes em suporte@lexendscholar.com.br, vamos priorizar 
com nossa equipe de produto. Sua opinião é fundamental para melhorarmos!
```

**Template Negativo — Desempenho/Lentidão:**
```
Olá, [Nome]! Pedimos desculpas pelo desempenho abaixo do esperado. 
A versão [X.X] que lançamos traz melhorias significativas nessa área. 
Por favor, atualize o app e nos diga se melhorou. Qualquer dúvida: suporte@lexendscholar.com.br
```

### Reviews 3 Estrelas (Neutro)

**Template Neutro:**
```
Olá, [Nome]! Agradecemos por compartilhar sua experiência. 
Gostaríamos de entender melhor o que podemos melhorar — pode nos escrever em 
suporte@lexendscholar.com.br? Seu feedback vai diretamente para nossa equipe de produto. 
Obrigado!
```

### Reviews 4–5 Estrelas (Positivo)

**Template Positivo:**
```
Olá, [Nome]! Que alegria receber seu feedback! É exatamente isso que nos motiva a 
continuar melhorando o Lexend Scholar. Em breve teremos novidades ainda melhores. 
Continue acompanhando as atualizações!
```

---

## 3. Cadência de Monitoramento Semanal

### Rotina Semanal (toda segunda-feira)

| Horário | Atividade | Responsável |
|---------|-----------|-------------|
| 09:00 | Verificar novos reviews App Store (últimos 7 dias) | Marketing |
| 09:15 | Verificar novos reviews Google Play (últimos 7 dias) | Marketing |
| 09:30 | Responder todos os reviews 1–3 estrelas sem resposta | Marketing |
| 09:45 | Registrar rating médio na planilha de monitoramento | Marketing |
| 10:00 | Escalar reviews com bug confirmado para Engineering | Marketing → Eng |

### Planilha de Monitoramento

| Semana | Rating iOS | Rating Android | Reviews Novos | Respondidos | Rating Meta |
|--------|-----------|----------------|--------------|-------------|-------------|
| W01 | — | — | — | — | > 4.5 |
| W02 | — | — | — | — | > 4.5 |
| W03 | — | — | — | — | > 4.5 |
| W04 | — | — | — | — | > 4.5 |

### Alertas Críticos

- Rating cair abaixo de 4.0: escalar imediatamente para Head of Product
- Mais de 3 reviews negativos sobre o mesmo bug em 48h: abrir incidente P1
- Review de cliente importante (escola > 500 alunos): responder em 2h

---

## 4. Ferramentas de Monitoramento

| Ferramenta | Uso | Plano |
|-----------|-----|-------|
| AppFollow | Monitoramento de reviews em tempo real, alertas | Pro |
| App Store Connect | Reviews oficiais iOS, respostas | Gratuito |
| Google Play Console | Reviews Android, respostas | Gratuito |
| Slack #reviews-alerts | Notificações automáticas de novos reviews | — |

### Integração AppFollow → Slack

Configurar webhook do AppFollow para notificar canal `#reviews-alerts` sempre que:
- Novo review 1–2 estrelas
- Rating médio cair mais de 0.1 ponto em 7 dias
- Novo review com mais de 200 palavras (review detalhado)

---

## 5. Meta e KPIs

| KPI | Meta | Período |
|-----|------|---------|
| Rating médio iOS | > 4.5 | 30 dias após lançamento |
| Rating médio Android | > 4.5 | 30 dias após lançamento |
| % reviews respondidos | > 90% | Semanal |
| Tempo médio de resposta | < 24h | Reviews 1–3 estrelas |
| Taxa de conversão de review | > 2% de usuários ativos | Mensal |

---

## Referências

- [App Store Review Response — Apple](https://developer.apple.com/app-store/ratings-and-reviews/)
- [Google Play Review Response — Google](https://support.google.com/googleplay/android-developer/answer/7247459)
- [SKStoreReviewController — Apple Docs](https://developer.apple.com/documentation/storekit/skstorereviewcontroller)
