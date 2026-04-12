# LS-2 — Configurar PostgreSQL com Schema Escolar Completo

## Visão Geral

O Lexend Scholar utiliza PostgreSQL 15 via Supabase com um schema multi-tenant baseado em `school_id`. Este documento descreve a configuração, indexação, tipos e manutenção do banco.

## Schema Principal

O schema completo está em `database_schema.sql` na raiz do repositório e em `supabase/migrations/`. As entidades principais são:

### Tabelas por Domínio

| Domínio         | Tabelas                                                                 |
|-----------------|-------------------------------------------------------------------------|
| Tenants         | `schools`                                                               |
| Identidade      | `users`                                                                 |
| Acadêmico       | `academic_years`, `academic_periods`, `classes`, `subjects`             |
| Alunos          | `students`, `guardians`, `student_guardians`                            |
| Frequência      | `attendance_records`                                                    |
| Notas           | `grades`, `grade_items`                                                 |
| Financeiro      | `invoices`, `payments`                                                  |
| Comunicação     | `notifications`, `messages`                                             |

### ENUMs

```sql
CREATE TYPE plan_type            AS ENUM ('starter', 'pro', 'enterprise');
CREATE TYPE subscription_status  AS ENUM ('trialing', 'active', 'past_due', 'canceled', 'unpaid');
CREATE TYPE payment_status       AS ENUM ('pending', 'paid', 'failed', 'refunded');
CREATE TYPE invoice_status       AS ENUM ('draft', 'open', 'paid', 'void', 'uncollectible');
CREATE TYPE attendance_status    AS ENUM ('present', 'absent', 'late', 'excused');
CREATE TYPE gender_type          AS ENUM ('M', 'F', 'other');
CREATE TYPE role_type            AS ENUM ('admin', 'teacher', 'secretary', 'guardian', 'student');
```

## Índices de Performance

```sql
-- Escola (tenant root)
CREATE INDEX idx_users_school_id          ON users(school_id);
CREATE INDEX idx_students_school_id       ON students(school_id);
CREATE INDEX idx_classes_school_id        ON classes(school_id);
CREATE INDEX idx_subjects_school_id       ON subjects(school_id);

-- Frequência — queries por data e turma são as mais frequentes
CREATE INDEX idx_attendance_class_date    ON attendance_records(class_id, date);
CREATE INDEX idx_attendance_student       ON attendance_records(student_id);
CREATE INDEX idx_attendance_school_date   ON attendance_records(school_id, date);

-- Notas
CREATE INDEX idx_grades_student           ON grades(student_id);
CREATE INDEX idx_grades_subject_period    ON grades(subject_id, academic_period_id);

-- Financeiro
CREATE INDEX idx_invoices_school_status   ON invoices(school_id, status);
CREATE INDEX idx_invoices_due_date        ON invoices(due_date);
CREATE INDEX idx_payments_invoice         ON payments(invoice_id);

-- Notificações
CREATE INDEX idx_notifications_user       ON notifications(user_id, read, created_at DESC);
```

## Trigger de updated_at

Aplicado a todas as tabelas com coluna `updated_at`:

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar em cada tabela relevante
CREATE TRIGGER trg_schools_updated_at
  BEFORE UPDATE ON schools
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Repetir para students, classes, subjects, grades, invoices, etc.
```

## Soft Delete Pattern

Tabelas que suportam soft delete usam `deleted_at TIMESTAMPTZ`:

```sql
-- Exemplo: students
ALTER TABLE students ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_students_active ON students(school_id) WHERE deleted_at IS NULL;
```

Views para facilitar queries:

```sql
CREATE VIEW active_students AS
  SELECT * FROM students WHERE deleted_at IS NULL;

CREATE VIEW active_users AS
  SELECT * FROM users WHERE active = TRUE;
```

## Connection Pooling

Configuração recomendada via PgBouncer (Supabase gerenciado):

```
pool_mode = transaction
max_client_conn = 200
default_pool_size = 25
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 5
```

String de conexão para aplicações server-side (Next.js, workers):
```
postgresql://postgres.<ref>:<password>@aws-0-sa-east-1.pooler.supabase.com:6543/postgres
```

String de conexão direta (migrations, scripts):
```
postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres
```

## Manutenção

### VACUUM e ANALYZE

O Supabase executa autovacuum por padrão. Para tabelas de alta escrita (attendance_records, notifications):

```sql
ALTER TABLE attendance_records SET (autovacuum_vacuum_scale_factor = 0.01);
ALTER TABLE notifications SET (autovacuum_vacuum_scale_factor = 0.01);
```

### Particionamento (futuro)

Quando `attendance_records` superar 10M de linhas, particionar por `school_id` + ano:

```sql
-- Exemplo de particionamento futuro
CREATE TABLE attendance_records_2025 PARTITION OF attendance_records
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

## Aplicar Migrations

```bash
# Via Supabase CLI
supabase db push

# Via psql direto
psql $SUPABASE_DB_URL -f database_schema.sql

# Reset completo (apenas dev)
supabase db reset
```

## Verificação de Integridade

```sql
-- Verificar FK constraints
SELECT conname, conrelid::regclass, confrelid::regclass
FROM pg_constraint WHERE contype = 'f';

-- Verificar índices existentes
SELECT schemaname, tablename, indexname
FROM pg_indexes WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Tamanho das tabelas
SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC;
```

## Referências

- `database_schema.sql` — schema completo
- `docs/infra/supabase-setup.md` — provisionamento dos projetos
- `docs/infra/rls-tenant.md` — configuração de RLS
- [Supabase Database Docs](https://supabase.com/docs/guides/database)
