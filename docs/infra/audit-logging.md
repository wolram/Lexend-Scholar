# LS-8 — Configurar Auditoria de Acesso a Dados Sensíveis

## Visão Geral

O Lexend Scholar processa dados pessoais de alunos, responsáveis e professores. A auditoria de acesso é necessária para conformidade com a LGPD e para investigação de incidentes de segurança.

## Dados Sensíveis Auditados

| Tabela           | Campos sensíveis                        | Operações auditadas |
|------------------|-----------------------------------------|---------------------|
| `students`       | CPF, data nascimento, endereço, gênero  | SELECT, UPDATE, DELETE |
| `users`          | email, telefone                         | UPDATE, DELETE      |
| `guardians`      | CPF, endereço, telefone                 | SELECT, UPDATE, DELETE |
| `grades`         | notas de avaliação                      | INSERT, UPDATE, DELETE |
| `invoices`       | valor, dados financeiros                | INSERT, UPDATE, DELETE |
| `payments`       | valor pago, método de pagamento         | INSERT, UPDATE      |

## Tabela de Auditoria

```sql
CREATE TABLE audit_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id     UUID REFERENCES schools(id) ON DELETE SET NULL,
  user_id       UUID,                         -- quem executou a ação
  action        TEXT NOT NULL,                -- INSERT, UPDATE, DELETE, SELECT_SENSITIVE
  table_name    TEXT NOT NULL,                -- tabela afetada
  record_id     UUID,                         -- ID do registro afetado
  old_values    JSONB,                        -- valores antes da mudança
  new_values    JSONB,                        -- valores após a mudança
  ip_address    INET,                         -- IP do cliente
  user_agent    TEXT,                         -- User-Agent da requisição
  metadata      JSONB,                        -- contexto adicional (rota, etc.)
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices para queries de auditoria
CREATE INDEX idx_audit_school_created  ON audit_logs(school_id, created_at DESC);
CREATE INDEX idx_audit_user_id         ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_table_record    ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_action          ON audit_logs(action, created_at DESC);

-- RLS: apenas admin pode ler logs de auditoria
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "audit_logs: admin read only"
  ON audit_logs FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'admin'
  );

-- Nenhum usuário pode deletar logs de auditoria via API
CREATE POLICY "audit_logs: no delete"
  ON audit_logs FOR DELETE
  TO authenticated
  USING (false);
```

## Triggers de Auditoria Automática

### Função genérica de auditoria

```sql
CREATE OR REPLACE FUNCTION audit_trigger_fn()
RETURNS TRIGGER AS $$
DECLARE
  audit_row audit_logs%ROWTYPE;
  excluded_columns TEXT[] := ARRAY['updated_at'];
BEGIN
  audit_row.id          := gen_random_uuid();
  audit_row.table_name  := TG_TABLE_NAME;
  audit_row.created_at  := NOW();

  -- Capturar contexto do JWT se disponível
  BEGIN
    audit_row.school_id := (current_setting('request.jwt.claims', true)::JSONB ->> 'school_id')::UUID;
    audit_row.user_id   := auth.uid();
  EXCEPTION WHEN OTHERS THEN
    NULL; -- contexto não disponível (ex: migration)
  END;

  IF TG_OP = 'INSERT' THEN
    audit_row.action     := 'INSERT';
    audit_row.record_id  := NEW.id;
    audit_row.new_values := to_jsonb(NEW);
    audit_row.old_values := NULL;
  ELSIF TG_OP = 'UPDATE' THEN
    audit_row.action     := 'UPDATE';
    audit_row.record_id  := NEW.id;
    audit_row.old_values := to_jsonb(OLD);
    audit_row.new_values := to_jsonb(NEW);
  ELSIF TG_OP = 'DELETE' THEN
    audit_row.action     := 'DELETE';
    audit_row.record_id  := OLD.id;
    audit_row.old_values := to_jsonb(OLD);
    audit_row.new_values := NULL;
  END IF;

  INSERT INTO audit_logs VALUES (audit_row.*);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### Aplicar triggers nas tabelas sensíveis

```sql
-- Students
CREATE TRIGGER audit_students
  AFTER INSERT OR UPDATE OR DELETE ON students
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Grades
CREATE TRIGGER audit_grades
  AFTER INSERT OR UPDATE OR DELETE ON grades
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Invoices
CREATE TRIGGER audit_invoices
  AFTER INSERT OR UPDATE OR DELETE ON invoices
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Payments
CREATE TRIGGER audit_payments
  AFTER INSERT OR UPDATE OR DELETE ON payments
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();

-- Users (mudanças de role ou desativação)
CREATE TRIGGER audit_users
  AFTER UPDATE OR DELETE ON users
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_fn();
```

## Log de Acesso via Sentry (Aplicação)

Para operações de leitura de dados sensíveis (SELECT), usar Sentry no nível da aplicação:

```typescript
// lib/audit.ts
import * as Sentry from '@sentry/nextjs'

export function auditSensitiveAccess(params: {
  action: string
  table: string
  recordId?: string
  schoolId: string
  userId: string
  metadata?: Record<string, unknown>
}) {
  Sentry.addBreadcrumb({
    category: 'audit',
    message: `${params.action} on ${params.table}`,
    level: 'info',
    data: {
      table: params.table,
      recordId: params.recordId,
      schoolId: params.schoolId,
      userId: params.userId,
      ...params.metadata,
    },
  })
}

// Uso em API routes
export async function GET(req: Request) {
  const { user, schoolId } = await getAuthContext(req)

  auditSensitiveAccess({
    action: 'READ_GRADES',
    table: 'grades',
    schoolId,
    userId: user.id,
    metadata: { route: '/api/students/[id]/grades' },
  })

  // ... resto do handler
}
```

## Logs de Autenticação

O Supabase Auth registra automaticamente eventos de autenticação:

- Logins bem-sucedidos e falhos
- Cadastros de novos usuários
- Resetagem de senha
- Revogação de tokens

Acessar em: **Dashboard → Auth → Logs**

Para exportar via API:

```bash
curl "https://<ref>.supabase.co/auth/v1/admin/audit" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY"
```

## Retenção de Logs

| Tipo de Log          | Retenção  | Destino          |
|----------------------|-----------|------------------|
| `audit_logs` (DB)    | 2 anos    | PostgreSQL       |
| Auth logs (Supabase) | 90 dias   | Supabase managed |
| Sentry breadcrumbs   | 30 dias   | Sentry cloud     |
| Vercel function logs | 3 dias    | Vercel           |
| Xcode Cloud logs     | 30 dias   | Xcode Cloud      |

## Alertas

Configurar alertas via Sentry ou PagerDuty para:

- Tentativas de acesso com role inválido (violação de policy RLS) > 5/min
- Deleções em massa (> 50 registros em 5 min)
- Logins com múltiplas falhas (> 10/hora por IP)
- Exportação de grades ou dados financeiros fora do horário comercial

## Consultas de Auditoria

```sql
-- Ações de um usuário nas últimas 24h
SELECT action, table_name, record_id, created_at
FROM audit_logs
WHERE user_id = '<user-uuid>'
  AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- Todas as deleções na escola nos últimos 7 dias
SELECT user_id, table_name, record_id, old_values, created_at
FROM audit_logs
WHERE school_id = '<school-uuid>'
  AND action = 'DELETE'
  AND created_at > NOW() - INTERVAL '7 days'
ORDER BY created_at DESC;

-- Alterações em notas de um aluno
SELECT user_id, old_values, new_values, created_at
FROM audit_logs
WHERE table_name = 'grades'
  AND record_id = '<grade-uuid>'
ORDER BY created_at DESC;
```

## Referências

- `docs/infra/rls-roles.md` — controle de acesso por role
- `docs/infra/encryption-ssl.md` — criptografia de dados
- `docs/infra/sentry-ios-setup.md` — configuração Sentry
- [LGPD - Lei 13.709/2018](https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm)
