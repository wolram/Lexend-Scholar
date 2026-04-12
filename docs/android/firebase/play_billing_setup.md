# Play Billing Library 6+ — Configuração Android (Lexend Scholar)

## Visão Geral

O Lexend Scholar oferece assinaturas recorrentes (Starter/Pro/Enterprise) tanto via web (Stripe) quanto via Google Play para o app Android. Este documento cobre a integração com Play Billing Library 6.

**Nota:** A Play Billing Library 6 introduziu a API `BillingClient.Builder` com suporte nativo a `ProductDetails` e subscriptions com múltiplas ofertas/pricing phases.

---

## 1. Dependências Gradle

`android/app/build.gradle`:
```groovy
dependencies {
    // Play Billing Library 6
    implementation 'com.android.billingclient:billing-ktx:6.2.1'
}
```

---

## 2. Produtos de assinatura no Google Play Console

### Criar Subscriptions

No [Google Play Console](https://play.google.com/console):

1. Selecione o app → **Monetização** → **Produtos** → **Assinaturas**
2. Crie 3 produtos:

| ID do produto               | Nome                      | Preço      |
|-----------------------------|---------------------------|------------|
| `lexend_starter_monthly`    | Lexend Scholar Starter    | R$ 297,00  |
| `lexend_pro_monthly`        | Lexend Scholar Pro        | R$ 697,00  |
| `lexend_enterprise_monthly` | Lexend Scholar Enterprise | R$ 1.497,00|

3. Para cada produto, configure:
   - **Período base**: 1 mês
   - **Período de teste gratuito**: 14 dias
   - **Tipo de renovação**: Auto-renovável

---

## 3. Implementação — BillingManager.kt

`android/app/src/main/java/com/lexendscholar/app/billing/BillingManager.kt`:

```kotlin
package com.lexendscholar.app.billing

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

class BillingManager(private val context: Context) : PurchasesUpdatedListener {

    companion object {
        val PRODUCT_IDS = listOf(
            "lexend_starter_monthly",
            "lexend_pro_monthly",
            "lexend_enterprise_monthly"
        )
    }

    private val _billingState = MutableStateFlow<BillingState>(BillingState.Idle)
    val billingState: StateFlow<BillingState> = _billingState

    private var billingClient: BillingClient = BillingClient.newBuilder(context)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder()
                .enableOneTimeProducts()
                .build()
        )
        .build()

    // -------------------------------------------------------------------------
    // Connect to Google Play
    // -------------------------------------------------------------------------
    suspend fun connect(): Boolean = suspendCancellableCoroutine { continuation ->
        billingClient.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billingResult: BillingResult) {
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    continuation.resume(true)
                } else {
                    _billingState.value = BillingState.Error(billingResult.debugMessage)
                    continuation.resume(false)
                }
            }
            override fun onBillingServiceDisconnected() {
                _billingState.value = BillingState.Disconnected
            }
        })
    }

    // -------------------------------------------------------------------------
    // Query available subscription products
    // -------------------------------------------------------------------------
    suspend fun queryProducts(): List<ProductDetails> {
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

        if (result.billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
            _billingState.value = BillingState.Error(result.billingResult.debugMessage)
            return emptyList()
        }

        return result.productDetailsList ?: emptyList()
    }

    // -------------------------------------------------------------------------
    // Launch subscription purchase flow
    // -------------------------------------------------------------------------
    fun launchSubscriptionFlow(activity: Activity, productDetails: ProductDetails) {
        // Use the first offer available (includes free trial if configured in Play Console)
        val offerToken = productDetails.subscriptionOfferDetails
            ?.firstOrNull()
            ?.offerToken
            ?: run {
                _billingState.value = BillingState.Error("No offer token available")
                return
            }

        val productDetailsParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(productDetails)
            .setOfferToken(offerToken)
            .build()

        val flowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(productDetailsParams))
            .build()

        val billingResult = billingClient.launchBillingFlow(activity, flowParams)

        if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
            _billingState.value = BillingState.Error(billingResult.debugMessage)
        }
    }

    // -------------------------------------------------------------------------
    // PurchasesUpdatedListener — called after user completes/cancels purchase
    // -------------------------------------------------------------------------
    override fun onPurchasesUpdated(billingResult: BillingResult, purchases: List<Purchase>?) {
        when (billingResult.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases?.forEach { purchase ->
                    handlePurchase(purchase)
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                _billingState.value = BillingState.Canceled
            }
            else -> {
                _billingState.value = BillingState.Error(billingResult.debugMessage)
            }
        }
    }

    // -------------------------------------------------------------------------
    // handlePurchase — acknowledge and send token to server
    // -------------------------------------------------------------------------
    private fun handlePurchase(purchase: Purchase) {
        if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED) return

        // Acknowledge purchase (required within 3 days or Google refunds)
        if (!purchase.isAcknowledged) {
            val params = AcknowledgePurchaseParams.newBuilder()
                .setPurchaseToken(purchase.purchaseToken)
                .build()

            billingClient.acknowledgePurchase(params) { billingResult ->
                if (billingResult.responseCode == BillingClient.BillingResponseCode.OK) {
                    _billingState.value = BillingState.PurchaseSuccess(purchase)
                    // Send purchaseToken to backend for server-side verification
                    sendPurchaseToServer(purchase)
                }
            }
        } else {
            _billingState.value = BillingState.PurchaseSuccess(purchase)
        }
    }

    // -------------------------------------------------------------------------
    // sendPurchaseToServer — validate purchase token via Google Play API
    // -------------------------------------------------------------------------
    private fun sendPurchaseToServer(purchase: Purchase) {
        // POST /api/billing/google-play/verify with:
        //   { purchaseToken, productId, packageName }
        // Backend uses Google Play Developer API to verify and activate subscription
        android.util.Log.d("BillingManager", "TODO: send to server - token: ${purchase.purchaseToken.take(20)}...")
    }

    // -------------------------------------------------------------------------
    // queryExistingSubscriptions
    // -------------------------------------------------------------------------
    suspend fun queryExistingSubscriptions(): List<Purchase> {
        val result = billingClient.queryPurchasesAsync(
            QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.SUBS)
                .build()
        )
        return result.purchasesList
    }

    fun disconnect() {
        billingClient.endConnection()
    }
}

// ---------------------------------------------------------------------------
// BillingState sealed class
// ---------------------------------------------------------------------------
sealed class BillingState {
    object Idle : BillingState()
    object Disconnected : BillingState()
    object Canceled : BillingState()
    data class PurchaseSuccess(val purchase: Purchase) : BillingState()
    data class Error(val message: String) : BillingState()
}
```

---

## 4. Uso na Activity/Fragment

```kotlin
class SubscriptionActivity : AppCompatActivity() {
    private lateinit var billingManager: BillingManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        billingManager = BillingManager(this)

        lifecycleScope.launch {
            val connected = billingManager.connect()
            if (connected) {
                val products = billingManager.queryProducts()
                displayProducts(products)
            }
        }

        lifecycleScope.launch {
            billingManager.billingState.collect { state ->
                when (state) {
                    is BillingState.PurchaseSuccess -> {
                        showSuccess("Assinatura ativada com sucesso!")
                    }
                    is BillingState.Error -> {
                        showError("Erro: ${state.message}")
                    }
                    BillingState.Canceled -> {
                        // User canceled — do nothing
                    }
                    else -> {}
                }
            }
        }
    }

    private fun displayProducts(products: List<ProductDetails>) {
        products.forEach { product ->
            val offer = product.subscriptionOfferDetails?.firstOrNull()
            val price = offer?.pricingPhases?.pricingPhaseList?.lastOrNull()?.formattedPrice
            // Build UI card for each product
            // product.name, price, product.description
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        billingManager.disconnect()
    }
}
```

---

## 5. Backend — verificação server-side

`webapp/api/google_play_verify.js`:
```js
// POST /api/billing/google-play/verify
// Usa googleapis npm package para verificar via Google Play Developer API
import { google } from 'googleapis';

export async function verifyPlayPurchase(req, res) {
  const { purchaseToken, productId } = req.body;
  const schoolId = req.session?.schoolId;

  const auth = new google.auth.GoogleAuth({
    credentials: JSON.parse(process.env.GOOGLE_PLAY_SERVICE_ACCOUNT),
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });

  const androidPublisher = google.androidpublisher({ version: 'v3', auth });

  const { data } = await androidPublisher.purchases.subscriptions.get({
    packageName: 'com.lexendscholar.app',
    subscriptionId: productId,
    token: purchaseToken,
  });

  if (data.cancelReason !== undefined && data.cancelReason !== null) {
    return res.status(400).json({ error: 'Subscription canceled' });
  }

  // data.expiryTimeMillis indica quando expira
  // Ative a subscription no Supabase para a escola
  // ...

  return res.status(200).json({ verified: true, expiresAt: data.expiryTimeMillis });
}
```

---

## 6. Variáveis de ambiente necessárias

```env
GOOGLE_PLAY_SERVICE_ACCOUNT={"type":"service_account","project_id":"..."}
```

Obtenha em: Google Play Console → Configuração → Acesso à API → Conta de serviço
