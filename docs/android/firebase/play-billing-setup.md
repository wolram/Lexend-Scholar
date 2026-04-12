# Play Billing Library 6+ — Setup Android

Guia de implementação de in-app billing para o app Lexend Scholar Android, usando Play Billing Library 7.

---

## 1. Dependência Gradle

### android/app/build.gradle

```kotlin
dependencies {
    implementation("com.android.billingclient:billing:7.0.0")
    implementation("com.android.billingclient:billing-ktx:7.0.0") // Extensões Kotlin/Coroutines
}
```

---

## 2. Produtos no Google Play Console

Cadastrar os 3 produtos de assinatura no Play Console:

| Product ID | Nome | Descrição |
|-----------|------|-----------|
| `ls_starter_monthly` | Lexend Scholar Starter | Gestão escolar até 100 alunos |
| `ls_pro_monthly` | Lexend Scholar Pro | Gestão escolar até 500 alunos + app |
| `ls_enterprise_monthly` | Lexend Scholar Enterprise | Gestão escolar ilimitada + API |

---

## 3. Configurar BillingClient

```kotlin
package br.com.lexendscholar.billing

import android.content.Context
import com.android.billingclient.api.*
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class LexendBillingManager(private val context: Context) {

    private val purchasesUpdatedListener = PurchasesUpdatedListener { billingResult, purchases ->
        when (billingResult.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    handlePurchase(purchase)
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                // Usuário cancelou o fluxo — não é erro
            }
            else -> {
                // Erro no billing
                handleBillingError(billingResult)
            }
        }
    }

    val billingClient: BillingClient = BillingClient.newBuilder(context)
        .setListener(purchasesUpdatedListener)
        .enablePendingPurchases()
        .build()

    /**
     * Conectar ao Play Billing Service.
     * Deve ser chamado antes de qualquer operação de billing.
     */
    suspend fun startConnection(): Boolean = suspendCancellableCoroutine { continuation ->
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                continuation.resume(billingResult.responseCode == BillingClient.BillingResponseCode.OK)
            }

            override fun onBillingServiceDisconnected() {
                // Tentar reconectar
                continuation.resume(false)
            }
        })
    }

    fun endConnection() {
        billingClient.endConnection()
    }
}
```

---

## 4. Consultar Produtos com queryProductDetailsAsync

```kotlin
private val PRODUCT_IDS = listOf(
    "ls_starter_monthly",
    "ls_pro_monthly",
    "ls_enterprise_monthly"
)

/**
 * Busca os detalhes dos produtos de assinatura no Play Store.
 * Retorna null em caso de erro.
 */
suspend fun queryProductDetails(): List<ProductDetails>? {
    val productList = PRODUCT_IDS.map { productId ->
        QueryProductDetailsParams.Product.newBuilder()
            .setProductId(productId)
            .setProductType(BillingClient.ProductType.SUBS)
            .build()
    }

    val params = QueryProductDetailsParams.newBuilder()
        .setProductList(productList)
        .build()

    val result = billingClient.queryProductDetails(params)

    return if (result.billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
        result.productDetailsList
    } else {
        null
    }
}
```

---

## 5. Iniciar Fluxo de Compra com launchBillingFlow

```kotlin
/**
 * Inicia o fluxo de compra do Play Store para o produto selecionado.
 *
 * @param activity Activity atual (necessária para o dialog do Play)
 * @param productDetails Detalhes do produto retornados por queryProductDetails()
 * @param offerToken Token da oferta (primeiro plano disponível por padrão)
 */
fun launchBillingFlow(
    activity: android.app.Activity,
    productDetails: ProductDetails,
    offerToken: String? = productDetails.subscriptionOfferDetails?.firstOrNull()?.offerToken
) {
    if (offerToken == null) {
        // Produto não possui ofertas disponíveis
        return
    }

    val productDetailsParams = BillingFlowParams.ProductDetailsParams.newBuilder()
        .setProductDetails(productDetails)
        .setOfferToken(offerToken)
        .build()

    val billingFlowParams = BillingFlowParams.newBuilder()
        .setProductDetailsParamsList(listOf(productDetailsParams))
        .build()

    billingClient.launchBillingFlow(activity, billingFlowParams)
}
```

---

## 6. Tratar Resultado em onPurchasesUpdated

```kotlin
/**
 * Trata os estados possíveis de uma compra:
 *   PURCHASED  — compra confirmada, verificar server-side e conceder acesso
 *   PENDING    — pagamento pendente (boleto, etc.) — aguardar confirmação
 *   USER_CANCELED — usuário fechou o dialog — não fazer nada
 */
private fun handlePurchase(purchase: Purchase) {
    when (purchase.purchaseState) {
        Purchase.PurchaseState.PURCHASED -> {
            if (!purchase.isAcknowledged) {
                // 1. Verificar compra no servidor antes de conceder acesso
                verifyPurchaseServerSide(purchase)
            }
        }
        Purchase.PurchaseState.PENDING -> {
            // Compra pendente — exibir mensagem ao usuário
            notifyPurchasePending(purchase)
        }
        Purchase.PurchaseState.UNSPECIFIED_STATE -> {
            // Estado desconhecido — ignorar
        }
    }
}

/**
 * Verificação server-side: envia purchaseToken ao backend para validar
 * com a Google Play Developer API e atualizar a subscription no Stripe.
 */
private fun verifyPurchaseServerSide(purchase: Purchase) {
    // Lançar coroutine ou trabalho em background
    CoroutineScope(Dispatchers.IO).launch {
        try {
            val response = LexendApi.verifyPurchase(
                productId     = purchase.products.first(),
                purchaseToken = purchase.purchaseToken
            )

            if (response.isValid) {
                // Confirmar a compra no Play para evitar reembolso automático
                acknowledgePurchase(purchase)
                // Atualizar estado da assinatura na UI
                withContext(Dispatchers.Main) {
                    onSubscriptionActivated(purchase.products.first())
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

/**
 * acknowledgePurchase — obrigatório dentro de 3 dias da compra.
 * Se não for feito, o Play Store reembolsa automaticamente.
 */
private suspend fun acknowledgePurchase(purchase: Purchase) {
    val params = AcknowledgePurchaseParams.newBuilder()
        .setPurchaseToken(purchase.purchaseToken)
        .build()

    val result = billingClient.acknowledgePurchase(params)
    if (result.responseCode != BillingClient.BillingResponseCode.OK) {
        throw Exception("acknowledgePurchase falhou: ${result.debugMessage}")
    }
}
```

---

## 7. Verificação Server-Side: POST /billing/verify-purchase

### Endpoint no backend (Express)

```javascript
// webapp/api/verify-purchase.js
import express from 'express';
import { google } from 'googleapis';

const router = express.Router();

/**
 * POST /billing/verify-purchase
 * Body: { productId, purchaseToken, schoolId }
 *
 * Verifica o purchaseToken com a Google Play Developer API
 * e atualiza a subscription no Stripe e no banco de dados.
 */
router.post('/', async (req, res) => {
  const { productId, purchaseToken, schoolId } = req.body;

  if (!productId || !purchaseToken || !schoolId) {
    return res.status(400).json({ error: 'Parâmetros obrigatórios: productId, purchaseToken, schoolId' });
  }

  try {
    // Autenticar com Google Play Developer API
    const auth = new google.auth.GoogleAuth({
      keyFile: process.env.GOOGLE_SERVICE_ACCOUNT_KEY_PATH,
      scopes:  ['https://www.googleapis.com/auth/androidpublisher'],
    });

    const androidpublisher = google.androidpublisher({ version: 'v3', auth });

    // Validar subscription no Play Store
    const { data: subscription } = await androidpublisher.purchases.subscriptions.get({
      packageName:   'br.com.lexendscholar',
      subscriptionId: productId,
      token:          purchaseToken,
    });

    const isValid = subscription.paymentState === 1 || // Pagamento recebido
                    subscription.paymentState === 2;   // Trial gratuito

    if (!isValid) {
      return res.status(400).json({ isValid: false, error: 'Compra não confirmada' });
    }

    // TODO: Atualizar subscription no Stripe e no banco
    // await updateStripeSubscription(schoolId, productId);

    return res.status(200).json({ isValid: true, subscription });
  } catch (err) {
    console.error('[VerifyPurchase]', err);
    return res.status(500).json({ error: 'Erro ao verificar compra' });
  }
});

export default router;
```

### Endpoint chamado pelo app Android (LexendApi.kt)

```kotlin
object LexendApi {
    suspend fun verifyPurchase(productId: String, purchaseToken: String): VerifyPurchaseResponse {
        val body = JSONObject().apply {
            put("productId",      productId)
            put("purchaseToken",  purchaseToken)
            put("schoolId",       SessionManager.schoolId)
        }.toString()

        // Usar Retrofit ou OkHttp para chamar POST /billing/verify-purchase
        // ...
    }
}
```

---

## 8. Tratamento de Estados Completo

| Estado | Código | Ação |
|--------|--------|------|
| Compra confirmada | `PURCHASED` | Verificar server-side → `acknowledgePurchase()` → conceder acesso |
| Pagamento pendente | `PENDING` | Exibir mensagem "aguardando pagamento", não conceder acesso |
| Usuário cancelou | `USER_CANCELED` | Fechar dialog, não fazer nada |
| Erro de rede | `NETWORK_ERROR` | Exibir retry |
| Billing indisponível | `BILLING_UNAVAILABLE` | Exibir mensagem de erro |
| Item não disponível | `ITEM_UNAVAILABLE` | Log + analytics |

---

## Referências

- [Play Billing Library 7 — Documentação oficial](https://developer.android.com/google/play/billing/integrate)
- [Verificação server-side Play Developer API](https://developer.android.com/google/play/billing/security)
- [Subscription purchases.get](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions/get)
