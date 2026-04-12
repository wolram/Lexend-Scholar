# Glance App Widgets — Setup Android

Guia de implementação de widgets para a tela inicial (Home Screen) usando Jetpack Glance.

---

## 1. Dependências Gradle

### android/app/build.gradle

```kotlin
dependencies {
    implementation("androidx.glance:glance-appwidget:1.1.0")
    implementation("androidx.glance:glance-material3:1.1.0")

    // WorkManager para atualizações periódicas
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}
```

---

## 2. Classes Principais

### LexendSummaryWidget — GlanceAppWidget

```kotlin
package br.com.lexendscholar.widgets

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.*
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import androidx.glance.color.ColorProviders
import br.com.lexendscholar.widgets.data.WidgetDataRepository

class LexendSummaryWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: android.content.Context, id: GlanceId) {
        // Buscar dados do Room local (não da API — suporte offline)
        val data = WidgetDataRepository(context).getWidgetSummary()

        provideContent {
            WidgetContent(data)
        }
    }
}

@Composable
fun WidgetContent(data: WidgetSummaryData) {
    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProviders.background)
            .padding(12.dp),
        verticalAlignment = Alignment.Vertical.Top
    ) {
        // Header
        Text(
            text = "Lexend Scholar",
            style = TextStyle(
                fontWeight = FontWeight.Bold,
                fontSize = 13.sp
            ),
            modifier = GlanceModifier.padding(bottom = 8.dp)
        )

        // Layout 2x2: 3 linhas de informação
        SummaryRow(
            label = "Próxima aula",
            value = data.nextClass ?: "Sem aulas hoje"
        )

        SummaryRow(
            label = "Frequência hoje",
            value = "${data.attendanceToday}%"
        )

        SummaryRow(
            label = "Inadimplentes",
            value = "${data.overdueCount} aluno(s)"
        )
    }
}

@Composable
fun SummaryRow(label: String, value: String) {
    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalAlignment = Alignment.Horizontal.Start
    ) {
        Text(
            text = "$label: ",
            style = TextStyle(fontSize = 11.sp),
            modifier = GlanceModifier.defaultWeight()
        )
        Text(
            text = value,
            style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 11.sp)
        )
    }
}
```

### Layout 4x2 — Com gráfico de frequência semanal

```kotlin
@Composable
fun WideWidgetContent(data: WidgetSummaryData) {
    Row(
        modifier = GlanceModifier.fillMaxSize().padding(12.dp)
    ) {
        // Coluna esquerda: resumo (igual ao 2x2)
        Column(
            modifier = GlanceModifier.defaultWeight(),
            verticalAlignment = Alignment.Vertical.Top
        ) {
            Text("Lexend Scholar", style = TextStyle(fontWeight = FontWeight.Bold, fontSize = 13.sp))
            SummaryRow("Próxima aula",    data.nextClass ?: "—")
            SummaryRow("Frequência hoje", "${data.attendanceToday}%")
            SummaryRow("Inadimplentes",   "${data.overdueCount} aluno(s)")
        }

        // Coluna direita: gráfico de frequência semanal
        Box(
            modifier = GlanceModifier
                .defaultWeight()
                .fillMaxHeight()
                .padding(start = 8.dp),
            contentAlignment = Alignment.Center
        ) {
            // Gráfico de barras simplificado com Box empilhadas
            WeeklyAttendanceChart(data.weeklyAttendance)
        }
    }
}

@Composable
fun WeeklyAttendanceChart(weeklyData: List<Int>) {
    val days = listOf("Seg", "Ter", "Qua", "Qui", "Sex")

    Row(
        modifier = GlanceModifier.fillMaxSize(),
        horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
        verticalAlignment = Alignment.Vertical.Bottom
    ) {
        weeklyData.zip(days).forEach { (percent, day) ->
            Column(
                modifier = GlanceModifier.padding(horizontal = 2.dp),
                horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                verticalAlignment = Alignment.Vertical.Bottom
            ) {
                // Barra de altura proporcional ao percentual
                Box(
                    modifier = GlanceModifier
                        .width(16.dp)
                        .height((percent * 0.4).dp) // máx ~40dp para 100%
                        .background(ColorProvider(android.graphics.Color.parseColor("#1E3A5F")))
                )
                Text(day, style = TextStyle(fontSize = 9.sp))
            }
        }
    }
}
```

### LexendWidgetReceiver — GlanceAppWidgetReceiver

```kotlin
package br.com.lexendscholar.widgets

import androidx.glance.appwidget.GlanceAppWidgetReceiver

class LexendWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = LexendSummaryWidget()
}
```

---

## 3. appwidget_info.xml

Criar em `res/xml/appwidget_info.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="110dp"
    android:targetCellWidth="2"
    android:targetCellHeight="2"
    android:maxResizeWidth="250dp"
    android:maxResizeHeight="110dp"
    android:resizeMode="horizontal|vertical"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/glance_default_loading_layout"
    android:description="@string/widget_description"
    android:widgetCategory="home_screen" />
```

> `updatePeriodMillis="0"` — as atualizações são gerenciadas pelo WorkManager, não pelo sistema Android (que tem limite mínimo de 30 minutos e gasta mais bateria).

---

## 4. Registrar no AndroidManifest.xml

```xml
<receiver
    android:name=".widgets.LexendWidgetReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/appwidget_info" />
</receiver>
```

---

## 5. Atualização Periódica com WorkManager

### WidgetUpdateWorker.kt

```kotlin
package br.com.lexendscholar.workers

import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.*
import br.com.lexendscholar.widgets.LexendSummaryWidget
import java.util.concurrent.TimeUnit

class WidgetUpdateWorker(
    private val context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        // Atualizar todos os widgets da tela inicial
        LexendSummaryWidget().updateAll(context)
        return Result.success()
    }

    companion object {
        private const val WORK_NAME = "lexend_widget_update"

        /**
         * Agendar atualização periódica a cada 30 minutos,
         * apenas quando há conexão de rede.
         */
        fun schedule(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val request = PeriodicWorkRequestBuilder<WidgetUpdateWorker>(
                repeatInterval = 30,
                repeatIntervalTimeUnit = TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .setBackoffCriteria(BackoffPolicy.LINEAR, 5, TimeUnit.MINUTES)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.UPDATE,
                request
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}
```

### Inicializar WorkManager na Application

```kotlin
// LexendApplication.kt
class LexendApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        WidgetUpdateWorker.schedule(this)
    }
}
```

---

## 6. Dados do Room Local (Offline-First)

Os dados do widget são buscados do Room local, **não da API**, para garantir funcionamento offline.

### WidgetSummaryData.kt

```kotlin
data class WidgetSummaryData(
    val nextClass:           String?,    // "Matemática - 8h00"
    val attendanceToday:     Int,        // 94 (%)
    val overdueCount:        Int,        // 3 (alunos inadimplentes)
    val weeklyAttendance:    List<Int>,  // [90, 88, 94, 91, 96] — Seg–Sex
    val updatedAt:           Long        // timestamp da última atualização
)
```

### WidgetDataRepository.kt

```kotlin
class WidgetDataRepository(private val context: Context) {
    private val db = LexendDatabase.getInstance(context)

    suspend fun getWidgetSummary(): WidgetSummaryData {
        val today = java.time.LocalDate.now()

        // Próxima aula do dia (baseado em horários da turma)
        val nextClass = db.classScheduleDao().getNextClassToday(today.toString())?.run {
            "$subjectName - ${startTime}"
        }

        // Frequência de hoje: presentes / total × 100
        val todayAttendance = db.attendanceDao().getTodayAttendance(today.toString())
        val attendanceToday = if (todayAttendance.total > 0) {
            (todayAttendance.present * 100) / todayAttendance.total
        } else 0

        // Total de alunos inadimplentes
        val overdueCount = db.financialDao().getOverdueCount()

        // Frequência da semana (últimos 5 dias úteis)
        val weeklyAttendance = db.attendanceDao().getWeeklyAttendance()
            .map { it.percentual }
            .take(5)

        return WidgetSummaryData(
            nextClass        = nextClass,
            attendanceToday  = attendanceToday,
            overdueCount     = overdueCount,
            weeklyAttendance = weeklyAttendance,
            updatedAt        = System.currentTimeMillis()
        )
    }
}
```

---

## Referências

- [Glance — Documentação oficial](https://developer.android.com/develop/ui/compose/glance)
- [Glance AppWidget](https://developer.android.com/develop/ui/compose/glance/create-app-widget)
- [WorkManager — Tarefas periódicas](https://developer.android.com/topic/libraries/architecture/workmanager/how-to/define-work)
- [Room — Banco de dados local](https://developer.android.com/training/data-storage/room)
