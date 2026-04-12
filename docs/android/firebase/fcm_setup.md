# Firebase Cloud Messaging — Configuração Android (Lexend Scholar)

## 1. Pré-requisitos

- Conta Firebase (console.firebase.google.com)
- Android Studio Hedgehog ou superior
- Kotlin 1.9+ / Gradle 8+

## 2. Criar projeto Firebase

1. Acesse https://console.firebase.google.com
2. Clique em **Adicionar projeto** → "Lexend Scholar"
3. Desative o Google Analytics (opcional)
4. Em **Cloud Messaging**, note o **Server key** e **Sender ID**

## 3. Adicionar app Android ao projeto Firebase

1. No console Firebase, clique em **Adicionar app** → ícone Android
2. Package name: `com.lexendscholar.app`
3. Apelido: "Lexend Scholar Android"
4. Faça download do `google-services.json`
5. Coloque em `android/app/google-services.json`

## 4. Configurar Gradle

### `android/build.gradle` (projeto)
```groovy
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.1'
    }
}

plugins {
    id 'com.google.gms.google-services' version '4.4.1' apply false
}
```

### `android/app/build.gradle` (módulo app)
```groovy
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
}

dependencies {
    // Firebase BOM — gerencia versões automaticamente
    implementation platform('com.google.firebase:firebase-bom:33.1.0')
    implementation 'com.google.firebase:firebase-messaging-ktx'
    implementation 'com.google.firebase:firebase-analytics-ktx'  // opcional
}
```

## 5. Criar o FirebaseMessagingService

Arquivo: `android/app/src/main/java/com/lexendscholar/app/LexendFirebaseService.kt`

```kotlin
package com.lexendscholar.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class LexendFirebaseService : FirebaseMessagingService() {

    companion object {
        const val CHANNEL_ID = "lexend_scholar_default"
        const val CHANNEL_NAME = "Notificações Lexend Scholar"
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Envia novo token para o backend
        CoroutineScope(Dispatchers.IO).launch {
            sendTokenToServer(token)
        }
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val title = remoteMessage.notification?.title ?: remoteMessage.data["title"] ?: "Lexend Scholar"
        val body = remoteMessage.notification?.body ?: remoteMessage.data["body"] ?: ""
        val type = remoteMessage.data["type"] ?: ""

        showNotification(title, body, type, remoteMessage.data)
    }

    private fun showNotification(title: String, body: String, type: String, data: Map<String, String>) {
        createNotificationChannel()

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("notification_type", type)
            data.forEach { (k, v) -> putExtra(k, v) }
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconRes = when (type) {
            "attendance_absent" -> R.drawable.ic_attendance
            "grade_released"    -> R.drawable.ic_grade
            "financial_due",
            "financial_overdue" -> R.drawable.ic_financial
            else                -> R.drawable.ic_notification
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alertas de frequência, notas e financeiro"
                enableVibration(true)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private suspend fun sendTokenToServer(token: String) {
        // Chama POST /api/notifications/register-token com o token FCM
        // Usar Retrofit ou Ktor client conforme padrão do projeto
        try {
            val api = ApiClient.instance   // seu cliente HTTP configurado
            val authToken = TokenStore.getAuthToken(applicationContext)
            api.registerFcmToken(
                authorization = "Bearer $authToken",
                body = RegisterTokenRequest(fcmToken = token)
            )
        } catch (e: Exception) {
            android.util.Log.e("LexendFCM", "Failed to register token: ${e.message}")
        }
    }
}
```

## 6. Registrar no AndroidManifest.xml

```xml
<manifest ...>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.INTERNET" />

    <application ...>
        <!-- Firebase Messaging Service -->
        <service
            android:name=".LexendFirebaseService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
    </application>
</manifest>
```

## 7. Solicitar permissão de notificação (Android 13+)

Em `MainActivity.kt`:
```kotlin
import android.Manifest
import androidx.activity.result.contract.ActivityResultContracts

class MainActivity : AppCompatActivity() {
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (!isGranted) {
            // Mostrar explicação ao usuário
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestNotificationPermission()
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
    }
}
```

## 8. Variáveis de ambiente no servidor (Node.js backend)

```env
FIREBASE_PROJECT_ID=lexend-scholar
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@lexend-scholar.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\n...\n-----END RSA PRIVATE KEY-----\n"
```

Obtenha as credenciais em: Firebase Console → Configurações do projeto → Contas de serviço → Gerar nova chave privada

## 9. Testar envio manual (servidor)

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/lexend-scholar/messages:send \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "DEVICE_FCM_TOKEN",
      "notification": {
        "title": "Teste Lexend Scholar",
        "body": "Notificação de teste enviada com sucesso!"
      }
    }
  }'
```

## 10. Tópicos FCM por escola (opcional)

Para broadcasts por escola sem armazenar tokens individualmente:
```kotlin
// No app Android (subscrever ao topic da escola)
FirebaseMessaging.getInstance().subscribeToTopic("school_${schoolId}")
    .addOnCompleteListener { task ->
        if (task.isSuccessful) Log.d("FCM", "Subscribed to school topic")
    }
```

No backend (enviar para topic):
```js
await messaging.send({
  topic: `school_${schoolId}`,
  notification: { title, body },
  data: { type, schoolId },
});
```
