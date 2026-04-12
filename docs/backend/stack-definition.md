# Lexend Scholar — Backend Stack Definition

## Overview

Lexend Scholar's backend is a multi-tenant SaaS API built on top of Supabase (PostgreSQL) and
deployed as Node.js/Express serverless functions. Each school is an isolated tenant identified
by `school_id` on every table; Row Level Security (RLS) in Supabase enforces tenant boundaries
at the database layer.

---

## Runtime & Language

| Layer | Technology | Version |
|---|---|---|
| Runtime | Node.js | 20 LTS |
| Language | JavaScript (ESM) | ES2022 |
| HTTP framework | Express | 4.x |
| Deployment | Vercel Serverless Functions | — |
| Database | PostgreSQL 15 via Supabase | — |
| Auth | Supabase Auth (JWT / GoTrue) | — |
| Storage | Supabase Storage (S3-compatible) | — |
| File exports | ExcelJS | 4.x |
| API Docs | OpenAPI 3.1 / Swagger UI | — |

---

## Supabase Configuration

```
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<service_role_key>   # server-side only
SUPABASE_ANON_KEY=<anon_key>                   # public / client-side
```

The service-role key bypasses RLS and is used only inside secure serverless functions.
Client-facing requests authenticate via the user's JWT (`Authorization: Bearer <token>`).

---

## Authentication Flow

1. Client logs in through Supabase Auth → receives `access_token` (JWT).
2. Every API request includes `Authorization: Bearer <access_token>`.
3. The `authenticateRequest` middleware (see `webapp/api/_middleware.js`) verifies the JWT with
   `supabase.auth.getUser(token)`.
4. The middleware attaches `req.user` (id, email, role, school_id via `app_metadata`) to the
   request context.
5. All database queries filter by `req.user.school_id` — never trust the body/query for tenant
   isolation.

---

## API Conventions

- **Base path:** `/api/`
- **Format:** JSON (`Content-Type: application/json`)
- **Pagination:** cursor-based for lists — `?limit=50&offset=0`
- **Soft delete:** records use `active = false` (never hard DELETE unless explicitly required)
- **Timestamps:** ISO-8601 UTC (`created_at`, `updated_at`)
- **Error shape:**
  ```json
  { "error": "Human-readable message", "code": "SNAKE_CASE_CODE" }
  ```
- **Success shape (list):**
  ```json
  { "data": [...], "total": 120, "limit": 50, "offset": 0 }
  ```
- **Success shape (single):**
  ```json
  { "data": { ... } }
  ```

---

## Module Structure

```
webapp/api/
  _middleware.js          — JWT auth + school_id extraction
  _supabase.js            — Supabase client factory (service role)
  crud-academico.js       — Students, teachers (users), classes (LS-70)
  matriculas-frequencia.js — Enrollments + attendance (LS-71)
  avaliacoes-notas.js     — Grade records (LS-72)
  financeiro.js           — Financial records / mensalidades (LS-74)

docs/backend/
  stack-definition.md     — This file (LS-69)
  openapi.yaml            — OpenAPI 3.1 spec (LS-76)

sql/
  migrations/
    001-add-missing-tables.sql   — Missing tables (LS-78)
    002-soft-delete-indexes.sql  — Soft delete + indexes (LS-83)
  seed/
    dev-seed.sql                 — Realistic dev seed data (LS-81)
```

---

## Security Checklist

- [ ] RLS enabled on all tables in Supabase dashboard.
- [ ] Service role key never exposed to the client.
- [ ] All list endpoints filter by `school_id`.
- [ ] Input validated before any database write.
- [ ] `SUPABASE_SERVICE_ROLE_KEY` stored as Vercel environment variable (never committed).

---

## Local Development

```bash
# Install dependencies
npm install

# Copy env vars
cp .env.example .env.local

# Run with nodemon
npx nodemon webapp/api/crud-academico.js

# Or use Vercel CLI
vercel dev
```

---

## Related Documents

- [`docs/backend/openapi.yaml`](./openapi.yaml) — Full API specification
- [`database_schema.sql`](../../database_schema.sql) — PostgreSQL schema
- [`sql/migrations/`](../../sql/migrations/) — Migration scripts
