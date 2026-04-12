# LS-7 — Implementar Criptografia e SSL/TLS

## Visão Geral

Este documento define a estratégia de criptografia em trânsito e em repouso para o Lexend Scholar, cobrindo banco de dados, APIs, armazenamento e aplicativo iOS.

## Criptografia em Trânsito (TLS)

### Supabase / PostgreSQL

O Supabase enforce SSL por padrão em todas as conexões. Verificar no dashboard:

- **Database → Settings → SSL Enforcement → Enabled**
- Versão mínima: TLS 1.2 (TLS 1.3 preferencial)

Para conexões via string de URL, garantir o parâmetro `sslmode`:

```bash
# Conexão segura
DATABASE_URL="postgresql://postgres:<pw>@db.<ref>.supabase.co:5432/postgres?sslmode=require"

# Verificar conexão SSL ativa
psql "$DATABASE_URL" -c "SELECT ssl, version FROM pg_stat_ssl WHERE pid = pg_backend_pid();"
```

### Vercel (Web App)

O Vercel provisiona automaticamente certificados SSL/TLS via Let's Encrypt para todos os domínios:

- HTTPS forçado (HTTP redireciona para HTTPS automaticamente)
- HSTS habilitado: `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
- Certificados renovados automaticamente

Configurar no `next.config.js`:

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          { key: 'Strict-Transport-Security', value: 'max-age=63072000; includeSubDomains; preload' },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-XSS-Protection', value: '1; mode=block' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=()' },
        ],
      },
    ]
  },
}
module.exports = nextConfig
```

### iOS App

O iOS já força HTTPS por padrão via App Transport Security (ATS). Verificar no `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <false/>
</dict>
```

Certificate pinning para o endpoint Supabase (usando TrustKit ou implementação manual):

```swift
// LexendScholarApp.swift — Certificate Pinning
import TrustKit

func configureCertificatePinning() {
    let trustKitConfig: [String: Any] = [
        kTSKSwizzleNetworkDelegates: false,
        kTSKPinnedDomains: [
            "<ref>.supabase.co": [
                kTSKExpirationDate: "2026-12-31",
                kTSKPublicKeyHashes: [
                    "<base64-sha256-spki-hash-1>",
                    "<base64-sha256-spki-hash-2>", // backup pin
                ],
                kTSKEnforcePinning: true,
                kTSKReportUris: ["https://sentry.io/..."],
            ]
        ]
    ]
    TrustKit.initSharedInstance(withConfiguration: trustKitConfig)
}
```

## Criptografia em Repouso

### PostgreSQL (Supabase)

O Supabase criptografa o armazenamento em repouso usando AES-256 gerenciado pela AWS:

- Volumes EBS criptografados com AWS KMS
- Snapshots de backup criptografados automaticamente
- Não requer configuração adicional

Para dados especialmente sensíveis (ex: CPF, dados bancários), aplicar criptografia no nível da aplicação:

```sql
-- Usar pgcrypto para criptografar campos sensíveis
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Função para criptografar CPF
CREATE OR REPLACE FUNCTION encrypt_pii(data TEXT) RETURNS TEXT AS $$
  SELECT encode(
    pgp_sym_encrypt(data, current_setting('app.encryption_key')),
    'base64'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Função para descriptografar
CREATE OR REPLACE FUNCTION decrypt_pii(data TEXT) RETURNS TEXT AS $$
  SELECT pgp_sym_decrypt(
    decode(data, 'base64'),
    current_setting('app.encryption_key')
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Configurar chave (via Supabase Vault ou .env)
ALTER DATABASE postgres SET app.encryption_key = '<ENCRYPTION_KEY>';
```

### Supabase Vault (recomendado para chaves sensíveis)

```sql
-- Armazenar secrets no Vault do Supabase
SELECT vault.create_secret('stripe_secret_key', 'sk_live_...');

-- Recuperar (apenas server-side com service_role)
SELECT decrypted_secret FROM vault.decrypted_secrets
WHERE name = 'stripe_secret_key';
```

### Storage (Arquivos)

O Supabase Storage armazena arquivos no S3 com criptografia SSE-S3 (AES-256) por padrão.

Buckets privados requerem URLs assinadas:

```typescript
// Gerar URL assinada para acesso temporário (10 min)
const { data } = await supabase.storage
  .from('documents')
  .createSignedUrl(`${schoolId}/${studentId}/report.pdf`, 600)
```

### iOS — Keychain

Chaves e tokens sensíveis no iOS devem ser armazenados no Keychain:

```swift
import Security

struct KeychainManager {
    static func save(key: String, value: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// Uso — nunca armazenar tokens em UserDefaults
KeychainManager.save(key: "supabase_access_token", value: session.accessToken)
```

## Gerenciamento de Chaves

| Chave                 | Armazenamento          | Rotação     |
|-----------------------|------------------------|-------------|
| DB Password           | GitHub Secrets         | 90 dias     |
| Service Role Key      | GitHub Secrets + Vault | 90 dias     |
| Encryption Key (PII)  | Supabase Vault         | 180 dias    |
| Stripe Secret Key     | GitHub Secrets + Vault | Anual       |
| APNs .p8 Key          | GitHub Secrets (base64)| Não expira* |
| iOS Provisioning      | Xcode Cloud            | Anual       |

*APNs .p8 keys não expiram, mas revogá-las se comprometidas.

## Checklist

- [ ] SSL enforced no Supabase (Dashboard → Database → SSL)
- [ ] TLS 1.2+ configurado para conexões de banco
- [ ] Headers de segurança configurados no Next.js
- [ ] HSTS habilitado no domínio de produção
- [ ] Certificate pinning configurado no iOS (TrustKit)
- [ ] Campos PII criptografados com pgcrypto ou Vault
- [ ] Storage buckets privados com signed URLs
- [ ] Tokens iOS armazenados no Keychain
- [ ] Nenhum secret no código ou logs

## Referências

- `docs/infra/env-secrets.md` — gerenciamento de variáveis
- `docs/infra/audit-logging.md` — auditoria de acesso
- [Supabase Vault](https://supabase.com/docs/guides/database/vault)
- [TrustKit iOS](https://github.com/datatheorem/TrustKit)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
