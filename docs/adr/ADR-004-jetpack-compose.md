# ADR-004 — Framework Android: Jetpack Compose + Kotlin

| Campo      | Valor                       |
|------------|-----------------------------|
| **Status** | Aceito                      |
| **Data**   | 2026-04-12                  |
| **Autores** | Marlow Sousa               |
| **Issue**  | LS-141                      |

---

## Contexto

O Lexend Scholar precisa de um aplicativo Android nativo para atender escolas cujos professores e diretores usam dispositivos Android — que representam ~75% do mercado de smartphones no Brasil.

Os requisitos são equivalentes ao app iOS (ADR-002):

- **Performance** em listas longas (chamada com 60+ alunos)
- **UI moderna** seguindo Material Design 3 (Material You)
- **Charts** para o dashboard de frequência e financeiro
- **Widgets** na home screen para diretores
- **Offline-first** para chamadas sem sinal
- **Target mínimo:** Android 8.0 (API 26) — cobre ~98% dos dispositivos ativos no Brasil

---

## Decisão

Adotar **Jetpack Compose** como framework de UI, com **Kotlin** e **Material Design 3**, seguindo a arquitetura recomendada pelo Google (Guide to App Architecture).

### Stack Android Definida

| Camada              | Tecnologia                                                   |
|---------------------|--------------------------------------------------------------|
| UI Framework        | Jetpack Compose (BOM estável mais recente)                   |
| Linguagem           | Kotlin (coroutines + Flow)                                   |
| Design System       | Material Design 3 (Material You)                             |
| Charts              | Vico (open-source, Compose-native) ou MPAndroidChart         |
| Widgets             | Glance API (Compose para App Widgets)                        |
| Persistência local  | Room + DataStore                                             |
| DI                  | Hilt (Dagger-based)                                          |
| Networking          | Ktor Client ou Retrofit + Supabase Kotlin SDK                |
| Navegação           | Navigation Compose                                           |
| Arquitetura         | MVVM + UiState + StateFlow                                   |

### Material You — Theming Dinâmico

O app adota Dynamic Color do Material You (Android 12+) para que o tema do app se adapte ao wallpaper do usuário. Em Android < 12, usa-se a paleta estática do Lexend Scholar (azul primário #1E40AF).

```kotlin
// Theme.kt
@Composable
fun LexendScholarTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.S,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && darkTheme -> dynamicDarkColorScheme(LocalContext.current)
        dynamicColor -> dynamicLightColorScheme(LocalContext.current)
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    MaterialTheme(colorScheme = colorScheme, content = content)
}
```

---

## Alternativas Consideradas e Descartadas

| Alternativa | Motivo de Descarte |
|-------------|-------------------|
| **XML Layouts (View System)** | Sistema legado — o Google recomenda Jetpack Compose para novos projetos desde 2021. XML é menos composável, requer mais boilerplate (ViewBinding, adapters, etc.), e não tem suporte nativo ao Glance API para widgets modernos. |
| **Flutter** | Cross-platform com boa performance. Porém: Dart como linguagem adicional; UI diverge do design nativo Android (não segue Material You dinamicamente); integração com APIs Android-específicas (WorkManager, Glance) é indireta via platform channels. Para o perfil de uso do Lexend Scholar (listas rápidas, widgets), o nativo é preferível. |
| **React Native** | Mesmos problemas do Flutter, com performance inferior em listas e charts. |
| **Kotlin Multiplatform (KMP)** | Tecnologia em evolução — compartilhar a camada de negócios entre iOS e Android é atrativo, mas a camada de UI ainda requer implementação separada (SwiftUI no iOS, Compose no Android). Considerar como evolução futura quando o time crescer. |

---

## Coerência com o App iOS (ADR-002)

A escolha do Jetpack Compose mantém coerência arquitetural com o SwiftUI do iOS:

| Conceito         | SwiftUI (iOS)          | Jetpack Compose (Android)    |
|------------------|------------------------|------------------------------|
| Paradigma        | Declarativo            | Declarativo                  |
| Estado           | `@State`, `@Observable` | `StateFlow`, `remember`     |
| Efeitos          | `.task`, `.onAppear`   | `LaunchedEffect`, `SideEffect` |
| Navegação        | `NavigationStack`      | `Navigation Compose`         |
| Async            | `async/await`          | Coroutines / Flow            |
| Composição       | `@ViewBuilder`         | `@Composable`                |

Essa paridade reduz o custo cognitivo para devs que trabalham nos dois apps.

---

## Consequências

### Positivas

- **UI moderna e performática:** Compose usa Canvas direto, sem overhead de inflação de XML. Listas com `LazyColumn` têm performance comparável a RecyclerView.
- **Material You nativo:** theming dinâmico sem código adicional em Android 12+.
- **Widgets modernos:** Glance API usa Compose para widgets de home screen — consistência com o resto do app.
- **Kotlin coroutines e Flow:** modelo de concorrência idiomático, sem callbacks aninhados.
- **Hilt:** injeção de dependências com suporte de compilação — menos erros em runtime.

### Negativas / Riscos

- **Curva de aprendizado:** devs com experiência em XML e RecyclerView precisam aprender o modelo mental declarativo do Compose.
- **API em evolução:** algumas APIs do Compose ainda recebem breaking changes entre versões estáveis. Usar BOM para gerenciar versões de forma coesa.
- **Charts:** não há biblioteca oficial de charts para Compose tão madura quanto Swift Charts no iOS. A biblioteca Vico é ativa e bem mantida, mas é de terceiros.
- **Target mínimo Android 8 (API 26):** Jetpack Compose suporta API 21+, então o target de API 26 não é uma limitação do framework — apenas uma decisão de negócio para cobrir o máximo de dispositivos.

---

## Revisão

Esta decisão será reavaliada se:
- Kotlin Multiplatform (KMP) atingir maturidade suficiente para compartilhar a camada de UI entre iOS e Android
- Flutter lançar suporte nativo completo a Material You dinâmico e APIs Android-específicas
- O time crescer com mais engenheiros iOS do que Android, tornando cross-platform mais econômico
