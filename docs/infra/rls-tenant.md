# LS-3 — Configurar Row Level Security (RLS) por Tenant

## Visão Geral

O Lexend Scholar é uma aplicação multi-tenant onde cada escola (`school_id`) é um tenant isolado. O RLS do PostgreSQL garante que nenhum usuário autenticado consiga acessar dados de outra escola, mesmo que tente manipular queries manualmente.

## Estratégia

1. **RLS habilitado em todas as tabelas** que contêm `school_id`
2. **JWT claim `school_id`** propagado via `auth.jwt()` do Supabase Auth
3. **Policies por role** (ver `docs/infra/rls-roles.md`)
4. **Service role** (backend) bypassa RLS para operações administrativas

## Configuração da Claim school_id no JWT

No Supabase Auth, adicionar um hook de `custom_access_token` para injetar `school_id` no JWT:

```sql
-- Função executada ao gerar o token de acesso
CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event JSONB)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  claims JSONB;
  user_school_id UUID;
BEGIN
  -- Buscar school_id do usuário autenticado
  SELECT school_id INTO user_school_id
  FROM public.users
  WHERE id = (event->>'user_id')::UUID;

  claims := event->'claims';
  claims := jsonb_set(claims, '{school_id}', to_jsonb(user_school_id::TEXT));
  claims := jsonb_set(claims, '{user_role}',
    (SELECT to_jsonb(role::TEXT) FROM public.users WHERE id = (event->>'user_id')::UUID)
  );

  RETURN jsonb_set(event, '{claims}', claims);
END;
$$;

GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM authenticated, anon, public;
```

Registrar o hook no dashboard: **Auth → Hooks → Custom Access Token Hook → custom_access_token_hook**

## Helper Functions

```sql
-- Retorna o school_id do usuário autenticado a partir do JWT
CREATE OR REPLACE FUNCTION auth.school_id() RETURNS UUID AS $$
  SELECT ((auth.jwt() ->> 'school_id')::UUID)
$$ LANGUAGE sql STABLE;

-- Retorna o role do usuário autenticado
CREATE OR REPLACE FUNCTION auth.user_role() RETURNS TEXT AS $$
  SELECT (auth.jwt() ->> 'user_role')
$$ LANGUAGE sql STABLE;
```

## Habilitar RLS e Policies por Tabela

### Tabela: schools

```sql
ALTER TABLE schools ENABLE ROW LEVEL SECURITY;

-- Escola só pode ver seus próprios dados
CREATE POLICY "schools: tenant isolation"
  ON schools FOR ALL
  USING (id = auth.school_id());
```

### Tabela: users

```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users: tenant isolation"
  ON users FOR ALL
  USING (school_id = auth.school_id());
```

### Tabela: students

```sql
ALTER TABLE students ENABLE ROW LEVEL SECURITY;

CREATE POLICY "students: tenant isolation"
  ON students FOR ALL
  USING (school_id = auth.school_id());
```

### Tabela: academic_years

```sql
ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;

CREATE POLICY "academic_years: tenant isolation"
  ON academic_years FOR ALL
  USING (school_id = auth.school_id());
```

### Tabela: academic_periods

```sql
ALTER TABLE academic_periods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "academic_periods: tenant isolation"
  ON academic_periods FOR ALL
  USING (school_id = auth.school_id());
```

### Tabela: classes

```sql
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "classes: tenant isolation"
  ON classes FOR ALL
  USING (school_id = auth.school_id());
```

### Tabela: subjects

```sql
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "subjects: tenant isolation"
  ON subjects FOR ALL
  USING (school_id = auth.school_id());
```

### Tabela: attendance_records

```sql
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "attendance_records: tenant isolation"
  ON attendance_records FOR ALL
  USING (school_id = auth.school_id());
```

### Tabela: grades

```sql
ALTER TABLE grades ENABLE ROW LEVEL SECURITY;

CREATE POLICY "grades: tenant isolation"
  ON grades FOR ALL
  USING (school_id = auth.school_id());
```

### Tabela: invoices

```sql
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "invoices: tenant isolation"
  ON invoices FOR ALL
  USING (school_id = auth.school_id());
```

### Tabela: payments

```sql
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "payments: tenant isolation"
  ON payments FOR ALL
  USING (
    invoice_id IN (
      SELECT id FROM invoices WHERE school_id = auth.school_id()
    )
  );
```

### Tabela: notifications

```sql
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications: tenant isolation"
  ON notifications FOR ALL
  USING (school_id = auth.school_id());
```

## Migration SQL Consolidada

Salvar em `supabase/migrations/20240101000002_rls_tenant.sql`:

```sql
-- Habilitar RLS em todas as tabelas de tenant
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY[
    'schools','users','students','guardians','student_guardians',
    'academic_years','academic_periods','classes','subjects',
    'attendance_records','grades','grade_items',
    'invoices','payments','notifications','messages'
  ]) LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
  END LOOP;
END;
$$;
```

## Verificação de RLS

```sql
-- Verificar tabelas com RLS ativo
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = TRUE
ORDER BY tablename;

-- Verificar policies existentes
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Testar isolamento (executar como usuário de escola A)
-- A query abaixo deve retornar APENAS registros da escola A
SET LOCAL role = authenticated;
SET LOCAL request.jwt.claims = '{"sub":"<user-id>","school_id":"<escola-a-id>","user_role":"admin"}';
SELECT count(*) FROM students; -- Deve retornar apenas alunos da escola A
```

## Considerações de Performance

- As funções `auth.school_id()` e `auth.user_role()` são `STABLE`, permitindo cache por query
- Políticas simples de igualdade (`school_id = auth.school_id()`) são altamente eficientes com índices em `school_id`
- Evitar subqueries complexas em policies — prefer JOINs diretos ou CTEs

## Referências

- `docs/infra/rls-roles.md` — políticas granulares por role (admin, teacher, guardian, student)
- `docs/infra/postgres-config.md` — configuração e índices
- [Supabase RLS Docs](https://supabase.com/docs/guides/auth/row-level-security)
