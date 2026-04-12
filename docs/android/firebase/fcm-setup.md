# Firebase Cloud Messaging (FCM) — Setup Android

Guia de configuração de push notifications para o app Lexend Scholar Android.

---

## 1. Pré-requisitos

- Projeto Firebase criado em [console.firebase.google.com](https://console.firebase.google.com)
- App Android cadastrado no projeto Firebase (package: `br.com.lexendscholar`)
- Android Studio com projeto Gradle configurado

---

## 2. Adicionar google-services.json

1. No Firebase Console: **Project Settings → Your apps → Download google-services.json**
2. Copiar o arquivo para `android/app/google-services.json`

```
android/
  app/
    google-services.json   ← aqui
    src/
    build.gradle
```

> **Nunca commitar** `google-services.json` em repositórios públicos — adicionar ao `.gitignore` se contiver dados sensíveis de projeto.

---

## 3. Dependências Gradle

### android/build.gradle (nível projeto)

```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.1" apply false
}
```

### android/app/build.gradle (nível módulo)

```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation("com.google.firebase:firebase-messaging:23.4.0")
    // Firebase BOM (opcional, para gerenciar versões automaticamente)
    implementation(platform("com.google.firebase:firebase-bom:32.7.2"))
}
```

---

## 4. Criar LexendFirebaseMessagingService

Criar o arquivo `LexendFirebaseMessagingService.kt`:

```kotlin
package br.com.lexendscholar.firebase

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import br.com.lexendscholar.MainActivity
import br.com.lexendscholar.R
import br.com.lexendscholar.api.DeviceApi
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class LexendFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        const val CHANNEL_ID = "lexend_alerts"
        const val CHANNEL_NAME = "Alertas Lexend Scholar"
    }

    /**
     * Chamado quando uma nova mensagem FCM é recebida.
     * Exibe uma notificação no canal "lexend_alerts".
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val title = remoteMessage.notification?.title
            ?: remoteMessage.data["title"]
            ?: "Lexend Scholar"
        val body = remoteMessage.notification?.body
            ?: remoteMessage.data["body"]
            ?: ""

        createNotificationChannel()
        showNotification(title, body, remoteMessage.data)
    }

    /**
     * Chamado quando o FCM gera um novo token para o dispositivo.
     * Envia o token ao backend via POST /devices/register.
     */
    override fun onNewToken(token: String) {
        super.onNewToken(token)

        CoroutineScope(Dispatchers.IO).launch {
            try {
                DeviceApi.registerToken(token)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun showNotification(title: String, body: String, data: Map<String, String>) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            // Passar dados para a activity (deep link ou navegação)
            data.forEach { (key, value) -> putExtra(key, value) }
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notificações do Lexend Scholar: presença, notas, pagamentos"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }
}
```

### Registrar no AndroidManifest.xml

```xml
<service
    android:name=".firebase.LexendFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

---

## 5. Registro do Token no Backend

Criar `DeviceApi.kt` para enviar o token FCM ao backend:

```kotlin
package br.com.lexendscholar.api

import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

object DeviceApi {
    private val client = OkHttpClient()
    private const val BASE_URL = "https://api.lexendscholar.com.br"

    /**
     * POST /devices/register
     * Registra ou atualiza o token FCM do dispositivo no banco de dados.
     */
    suspend fun registerToken(fcmToken: String) {
        val prefs = LexendApp.instance.getSharedPreferences("auth", 0)
        val authToken = prefs.getString("auth_token", null) ?: return

        val body = JSONObject().apply {
            put("fcm_token", fcmToken)
            put("platform", "android")
        }.toString().toRequestBody("application/json".toMediaType())

        val request = Request.Builder()
            .url("$BASE_URL/devices/register")
            .post(body)
            .addHeader("Authorization", "Bearer $authToken")
            .build()

        client.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                throw Exception("Falha ao registrar token FCM: ${response.code}")
            }
        }
    }
}
```

O backend deve persistir o `fcm_token` na coluna `users.fcm_token` (conforme `database_schema.sql`).

---

## 6. Tipos de Notificação e Payloads JSON

### new_message — Nova mensagem/comunicado

```json
{
  "notification": {
    "title": "Novo comunicado da escola",
    "body": "Reunião de pais na sexta-feira às 19h."
  },
  "data": {
    "type": "new_message",
    "message_id": "uuid-da-mensagem",
    "redirect_to": "comunicados"
  }
}
```

### attendance_registered — Frequência registrada

```json
{
  "notification": {
    "title": "Frequência registrada",
    "body": "João Silva marcou presença em Matemática hoje."
  },
  "data": {
    "type": "attendance_registered",
    "student_id": "uuid-do-aluno",
    "class_id": "uuid-da-turma",
    "date": "2026-04-12",
    "status": "present"
  }
}
```

### payment_overdue — Mensalidade em atraso

```json
{
  "notification": {
    "title": "Mensalidade em atraso",
    "body": "A mensalidade de Abril está vencida há 3 dias. Clique para regularizar."
  },
  "data": {
    "type": "payment_overdue",
    "financial_record_id": "uuid-do-registro",
    "days_overdue": "3",
    "amount": "59700",
    "redirect_to": "financeiro"
  }
}
```

### grade_posted — Nota lançada

```json
{
  "notification": {
    "title": "Nova nota disponível",
    "body": "João Silva recebeu nota 8.5 em Prova de Português — 1º Bimestre."
  },
  "data": {
    "type": "grade_posted",
    "student_id": "uuid-do-aluno",
    "subject": "Português",
    "grade_type": "prova",
    "score": "8.5",
    "period": "1º Bimestre"
  }
}
```

---

## 7. Envio via FCM REST API (Backend)

### Endpoint

```
POST https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send
Authorization: Bearer {ACCESS_TOKEN}
Content-Type: application/json
```

### Obter Access Token

```javascript
// Node.js — usando google-auth-library
import { GoogleAuth } from 'google-auth-library';

const auth = new GoogleAuth({
  scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
});

async function getFcmAccessToken() {
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  return tokenResponse.token;
}
```

### Exemplo de envio (Node.js)

```javascript
async function sendPushNotification({ fcmToken, title, body, data = {} }) {
  const accessToken = await getFcmAccessToken();
  const projectId   = process.env.FIREBASE_PROJECT_ID;

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: { title, body },
          data: Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)])
          ),
          android: {
            priority: 'high',
            notification: {
              channel_id: 'lexend_alerts',
              sound: 'default',
            },
          },
        },
      }),
    }
  );

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`FCM send failed: ${JSON.stringify(error)}`);
  }

  return await response.json();
}
```

---

## 8. Variáveis de Ambiente (Backend)

```env
FIREBASE_PROJECT_ID=lexend-scholar
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

---

## Referências

- [Firebase Cloud Messaging — Documentação oficial](https://firebase.google.com/docs/cloud-messaging/android/client)
- [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
- [google-auth-library-nodejs](https://github.com/googleapis/google-auth-library-nodejs)
