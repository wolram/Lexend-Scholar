# ADR-002 — Framework iOS: SwiftUI + Swift 6

| Campo      | Valor                       |
|------------|-----------------------------|
| **Status** | Aceito                      |
| **Data**   | 2026-04-12                  |
| **Autores** | Marlow Sousa               |
| **Issue**  | LS-141                      |

---

## Contexto

O Lexend Scholar requer um aplicativo iOS nativo para diretores, professores e secretaria. Os requisitos principais são:

- **Performance** em listas longas (ex: chamada com 60+ alunos em tela, scrolling suave)
- **UI moderna** alinhada com as guidelines da Apple (iOS 18 design language)
- **Charts e visualizações** para o dashboard (frequência por período, inadimplência)
- **Widgets** na tela inicial para diretores (frequência do dia, alunos em falta)
- **Offline-first** para que professores possam fazer chamada mesmo sem sinal
- **Target mínimo:** iOS 16 (covers ~97% dos dispositivos ativos segundo dados Apple, abril 2026)

O time tem familiaridade com Swift. A decisão afeta principalmente o app iOS — o app Android é coberto pelo ADR-004.

---

## Decisão

Adotar **SwiftUI** como framework de UI, com **Swift 6** e seu modelo de concorrência estruturada (structured concurrency) para operações assíncronas.

### Stack iOS Definida

| Camada              | Tecnologia                                          |
|---------------------|-----------------------------------------------------|
| UI Framework        | SwiftUI (iOS 16+)                                   |
| Linguagem           | Swift 6                                             |
| Concorrência        | Swift Structured Concurrency (`async/await`, `Actor`) |
| Charts              | Swift Charts (nativo, iOS 16+)                      |
| Widgets             | WidgetKit                                           |
| Persistência local  | SwiftData (iOS 17+) para cache offline              |
| Networking          | URLSession + Supabase Swift SDK                     |
| Navegação           | NavigationStack (iOS 16+)                           |

### Principais Padrões Adotados

- **MVVM + @Observable** (Swift 5.9+): ViewModels observáveis sem boilerplate de Combine
- **Actor isolation** para acesso thread-safe ao banco local e estado compartilhado
- **@MainActor** nos ViewModels para garantir updates de UI na thread correta

---

## Alternativas Consideradas e Descartadas

| Alternativa | Motivo de Descarte |
|-------------|-------------------|
| **UIKit** | Framework mais maduro e com mais recursos avançados, mas exige código significativamente mais verboso. Não tem Swift Charts nativo, WidgetKit integração é mais complexa. Para um time pequeno, a velocidade do SwiftUI supera as vantagens do UIKit no estágio atual. |
| **React Native** | Cross-platform (iOS + Android em um codebase), mas: performance inferior para listas longas e charts; sem acesso nativo aos frameworks Apple (WidgetKit, SwiftData); experiência de usuário menos fluida em gestures e animações. Para escola, onde a UX de chamada precisa ser rápida, o native é preferível. |
| **Flutter** | Cross-platform com boa performance, mas: Dart como linguagem adicional na stack; design não segue Material You nem Human Interface Guidelines nativamente; animações e integração com APIs iOS (Siri, WidgetKit) são limitadas. |
| **Expo / Capacitor** | Web-based, performance insuficiente para o perfil de uso (listas de alunos, operações frequentes). |

---

## Consequências

### Positivas

- **Velocidade de UI:** SwiftUI com Swift 6 permite construir telas complexas com muito menos código vs UIKit.
- **Design system coerente:** SF Symbols, Dynamic Type e acessibilidade integrados por padrão.
- **Charts nativos:** Swift Charts elimina dependência de bibliotecas de terceiros para o dashboard.
- **Widgets de primeiro nível:** WidgetKit integra naturalmente com SwiftUI para os widgets do diretor.
- **Concorrência segura:** Swift 6 strict concurrency elimina data races em compile time.

### Negativas / Riscos

- **Mínimo iOS 16 para usuários:** escolas com iPhones antigos (iOS 15 ou inferior) não conseguem usar o app. Aceitável dado que iOS 16+ representa ~97% do mercado em 2026.
- **Curva de aprendizado para devs UIKit:** desenvolvedores com background em UIKit precisam adaptar o modelo mental para SwiftUI (estado declarativo, ciclo de vida diferente).
- **APIs SwiftUI ainda evoluindo:** algumas APIs são marcadas como `@available(iOS 17, *)`, exigindo conditional availability em casos específicos para suportar iOS 16.

---

## Revisão

Esta decisão será reavaliada se:
- A escola demandar versão Android e o time precisar unificar o codebase (considerar KMP — Kotlin Multiplatform)
- Apple deprecar APIs relevantes em versões futuras do iOS
- O custo de manutenção de dois apps nativos (iOS + Android) tornar-se proibitivo para o time
