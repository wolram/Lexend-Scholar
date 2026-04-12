# App Widgets com Jetpack Glance — Resumo Escolar (Lexend Scholar)

## Visão Geral

Os widgets Glance do Lexend Scholar exibem na tela inicial do Android um resumo rápido: total de alunos presentes hoje, próximos eventos e alertas financeiros — sem abrir o app.

**Tecnologia:** Jetpack Glance 1.1.x (API Compose-based para widgets Android 5+)

---

## 1. Dependências Gradle

`android/app/build.gradle`:
```groovy
dependencies {
    // Jetpack Glance
    implementation "androidx.glance:glance-appwidget:1.1.0"
    implementation "androidx.glance:glance-material3:1.1.0"

    // WorkManager para atualização periódica
    implementation "androidx.work:work-runtime-ktx:2.9.0"
}
```

---

## 2. Widget de Resumo Escolar — SchoolSummaryWidget.kt

`android/app/src/main/java/com/lexendscholar/app/widget/SchoolSummaryWidget.kt`:

```kotlin
package com.lexendscholar.app.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.color.ColorProviders
import androidx.glance.material3.ColorProviders
import com.lexendscholar.app.MainActivity
import com.lexendscholar.app.R

// ---------------------------------------------------------------------------
// GlanceAppWidget
// ---------------------------------------------------------------------------
class SchoolSummaryWidget : GlanceAppWidget() {

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        // Fetch data from local cache (SharedPreferences or Room)
        val data = WidgetDataStore.getWidgetData(context)

        provideContent {
            SchoolSummaryContent(data)
        }
    }
}

// ---------------------------------------------------------------------------
// Widget UI Composable
// ---------------------------------------------------------------------------
@Composable
fun SchoolSummaryContent(data: WidgetData) {
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(ColorProvider(androidx.compose.ui.graphics.Color(0xFF137FEC)))
            .cornerRadius(16.dp)
            .clickable(actionStartActivity<MainActivity>())
            .padding(16.dp)
    ) {
        Column(modifier = GlanceModifier.fillMaxSize()) {

            // Header
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Image(
                    provider = ImageProvider(R.drawable.ic_widget_logo),
                    contentDescription = "Lexend Scholar",
                    modifier = GlanceModifier.size(20.dp)
                )
                Spacer(modifier = GlanceModifier.width(8.dp))
                Text(
                    text = "Lexend Scholar",
                    style = TextStyle(
                        color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }

            Spacer(modifier = GlanceModifier.height(12.dp))

            // Stats row
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                StatCard(
                    label = "Presentes hoje",
                    value = "${data.presentToday}/${data.totalStudents}",
                    modifier = GlanceModifier.defaultWeight()
                )
                Spacer(modifier = GlanceModifier.width(8.dp))
                StatCard(
                    label = "Faltas hoje",
                    value = "${data.absentToday}",
                    modifier = GlanceModifier.defaultWeight()
                )
            }

            Spacer(modifier = GlanceModifier.height(8.dp))

            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                StatCard(
                    label = "Inadimplentes",
                    value = "${data.overdueCount}",
                    modifier = GlanceModifier.defaultWeight()
                )
                Spacer(modifier = GlanceModifier.width(8.dp))
                StatCard(
                    label = "Eventos hoje",
                    value = "${data.eventsToday}",
                    modifier = GlanceModifier.defaultWeight()
                )
            }

            Spacer(modifier = GlanceModifier.height(8.dp))

            // Last update
            Text(
                text = "Atualizado: ${data.lastUpdated}",
                style = TextStyle(
                    color = ColorProvider(androidx.compose.ui.graphics.Color(0xCCFFFFFF)),
                    fontSize = 10.sp
                )
            )
        }
    }
}

@Composable
fun StatCard(label: String, value: String, modifier: GlanceModifier = GlanceModifier) {
    Column(
        modifier = modifier
            .background(ColorProvider(androidx.compose.ui.graphics.Color(0x33FFFFFF)))
            .cornerRadius(10.dp)
            .padding(horizontal = 10.dp, vertical = 8.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = TextStyle(
                color = ColorProvider(androidx.compose.ui.graphics.Color.White),
                fontSize = 20.sp,
                fontWeight = FontWeight.Bold
            )
        )
        Text(
            text = label,
            style = TextStyle(
                color = ColorProvider(androidx.compose.ui.graphics.Color(0xCCFFFFFF)),
                fontSize = 10.sp
            )
        )
    }
}

// ---------------------------------------------------------------------------
// GlanceAppWidgetReceiver
// ---------------------------------------------------------------------------
class SchoolSummaryWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = SchoolSummaryWidget()
}
```

---

## 3. Dados do Widget — WidgetDataStore.kt

```kotlin
package com.lexendscholar.app.widget

import android.content.Context
import androidx.core.content.edit
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Serializable
data class WidgetData(
    val presentToday: Int = 0,
    val absentToday: Int = 0,
    val totalStudents: Int = 0,
    val overdueCount: Int = 0,
    val eventsToday: Int = 0,
    val lastUpdated: String = "--:--"
)

object WidgetDataStore {
    private const val PREFS_NAME = "lexend_widget_prefs"
    private const val KEY_WIDGET_DATA = "widget_data"

    fun saveWidgetData(context: Context, data: WidgetData) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit {
            putString(KEY_WIDGET_DATA, Json.encodeToString(WidgetData.serializer(), data))
        }
    }

    fun getWidgetData(context: Context): WidgetData {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(KEY_WIDGET_DATA, null) ?: return WidgetData()
        return try {
            Json.decodeFromString(WidgetData.serializer(), json)
        } catch (e: Exception) {
            WidgetData()
        }
    }
}
```

---

## 4. WorkManager — atualização periódica

```kotlin
package com.lexendscholar.app.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.work.*
import com.lexendscholar.app.api.ApiClient
import java.util.concurrent.TimeUnit

class WidgetUpdateWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            val api = ApiClient.instance
            val summary = api.getWidgetSummary()  // GET /api/dashboard/widget-summary

            val data = WidgetData(
                presentToday = summary.presentToday,
                absentToday = summary.absentToday,
                totalStudents = summary.totalStudents,
                overdueCount = summary.overdueCount,
                eventsToday = summary.eventsToday,
                lastUpdated = java.text.SimpleDateFormat("HH:mm", java.util.Locale("pt", "BR"))
                    .format(java.util.Date())
            )

            WidgetDataStore.saveWidgetData(applicationContext, data)
            SchoolSummaryWidget().updateAll(applicationContext)

            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        private const val WORK_NAME = "lexend_widget_update"

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
    }
}
```

---

## 5. AndroidManifest.xml — Receiver do widget

```xml
<!-- Widget Receiver -->
<receiver
    android:name=".widget.SchoolSummaryWidgetReceiver"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/school_summary_widget_info" />
</receiver>
```

---

## 6. Widget Info XML

`android/app/src/main/res/xml/school_summary_widget_info.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider
    xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:targetCellWidth="3"
    android:targetCellHeight="2"
    android:updatePeriodMillis="1800000"
    android:initialLayout="@layout/widget_loading"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen"
    android:description="@string/widget_description"
    android:previewImage="@drawable/widget_preview" />
```

---

## 7. API Backend — GET /api/dashboard/widget-summary

```js
// webapp/api/widget_summary.js
export async function widgetSummaryHandler(req, res) {
  const schoolId = req.session?.schoolId;
  const supabase = getSupabase();
  const today = new Date().toISOString().split('T')[0];

  const [{ count: presentToday }, { count: absentToday }, { count: totalStudents },
         { count: overdueCount }, { count: eventsToday }] = await Promise.all([
    supabase.from('attendance_records').select('id', { count: 'exact', head: true })
      .eq('school_id', schoolId).eq('date', today).eq('status', 'present'),
    supabase.from('attendance_records').select('id', { count: 'exact', head: true })
      .eq('school_id', schoolId).eq('date', today).eq('status', 'absent'),
    supabase.from('students').select('id', { count: 'exact', head: true })
      .eq('school_id', schoolId).eq('active', true),
    supabase.from('financial_records').select('id', { count: 'exact', head: true })
      .eq('school_id', schoolId).eq('payment_status', 'pending').lt('due_date', today),
    supabase.from('academic_years').select('id', { count: 'exact', head: true })
      .eq('school_id', schoolId).eq('start_date', today),
  ]);

  return res.json({ presentToday, absentToday, totalStudents, overdueCount, eventsToday });
}
```

---

## 8. Agendar worker na inicialização

Em `Application.kt`:
```kotlin
class LexendScholarApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        WidgetUpdateWorker.schedule(this)
    }
}
```
