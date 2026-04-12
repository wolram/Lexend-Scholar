# Arquitetura Multi-Tenant — Lexend Scholar

## Visão Geral

O Lexend Scholar é uma plataforma SaaS multi-tenant onde cada escola é um **tenant completamente isolado**. O isolamento é garantido em nível de banco de dados via Row Level Security (RLS) do PostgreSQL, sem necessidade de schemas ou bancos separados por tenant.

---

## Modelo de Isolamento: Schema Compartilhado + RLS

```
┌─────────────────────────────────────────────────┐
│              PostgreSQL / Supabase               │
│                                                  │
│  ┌─────────────┐     ┌─────────────┐            │
│  │  Escola A   │     │  Escola B   │            │
│  │ school_id=X │     │ school_id=Y │            │
│  └──────┬──────┘     └──────┬──────┘            │
│         │                   │                   │
│    ┌────▼───────────────────▼────┐              │
│    │   public.students            │              │
│    │   school_id | id | name ...  │              │
│    │   X         | 1  | Ana       │              │
│    │   X         | 2  | João      │              │
│    │   Y         | 3  | Maria     │  ← escola B  │
│    └────────────────────────────-┘              │
│         │                                        │
│    RLS Policy: WHERE school_id = get_current_school_id()
│                                                  │
│   Usuário da Escola A vê apenas rows com school_id = X
└─────────────────────────────────────────────────┘
```

---

## Mecanismo de Isolamento

### 1. Coluna `school_id` em todas as tabelas
Toda tabela de dados possui `school_id UUID NOT NULL REFERENCES schools(id)`. Isso garante integridade referencial e é o pilar do isolamento.

### 2. Row Level Security (RLS)
RLS está habilitado em todas as tabelas (`ALTER TABLE x ENABLE ROW LEVEL SECURITY`). Sem uma política permissiva, nenhuma linha é visível.

### 3. Função `get_current_school_id()`
```sql
SELECT school_id FROM public.users WHERE auth_id = auth.uid()
```
Esta função é `SECURITY DEFINER` e é chamada em toda política RLS. Ela é o ponto central do isolamento: um usuário só pode ver dados do tenant ao qual pertence.

### 4. JWT-bound
O `auth.uid()` do Supabase é extraído do JWT assinado. Não é possível forjar o `auth.uid()` sem a chave JWT_SECRET do Supabase.

---

## Tabelas e Status RLS

Para verificar o status em produção:
```sql
SELECT * FROM public.check_rls_status();
```

Resultado esperado — todas as tabelas com `rls_enabled = true`:

| table_name                  | rls_enabled | policy_count |
|-----------------------------|-------------|--------------|
| attendance_records          | true        | 4            |
| audit_log                   | true        | 1            |
| classes                     | true        | 4            |
| financial_records           | true        | 4            |
| grade_records               | true        | 4            |
| grades                      | true        | 2            |
| guardians                   | true        | 4            |
| schools                     | true        | 2            |
| student_class_enrollments   | true        | 1+           |
| students                    | true        | 4            |
| subjects                    | true        | 2            |
| users                       | true        | 4            |

---

## Validação de Isolamento

### Verificar colunas school_id
```sql
SELECT * FROM public.validate_school_id_columns();
-- Todas devem retornar has_school_id=true, is_not_null=true
```

### Teste de isolamento cross-tenant
```sql
SELECT * FROM public.test_tenant_isolation(
  'uuid-escola-a',
  'uuid-escola-b'
);
-- Todos os testes devem retornar passed=true
```

### Simulação manual com set_config (para QA)
Para simular o acesso de um usuário de uma escola específica sem JWT real:

```sql
-- Em sessão de teste (NUNCA em produção):
SET LOCAL role TO authenticated;
SET LOCAL request.jwt.claims TO '{"sub": "uuid-do-auth-user", "role": "authenticated"}';

SELECT * FROM public.students;
-- Deve retornar apenas alunos do school_id do usuário simulado
```

---

## Garantias de Segurança

| Vetor de Ataque                        | Mitigação                                                              |
|----------------------------------------|------------------------------------------------------------------------|
| Usuário tenta acessar outra escola     | RLS filtra por `get_current_school_id()` — retorna zero rows           |
| Forge de `school_id` no request        | `school_id` vem de `public.users` via `auth.uid()`, não do cliente     |
| Acesso direto via SQL (vazamento de credenciais) | RLS é enforçado mesmo para queries diretas no PostgreSQL          |
| Bypass de RLS via function             | Todas as funções helper usam `SET search_path = public`                |
| Escalada de role                       | `role` é lido de `public.users`, não do JWT claim                     |
| Cross-tenant via JOIN                  | Cada tabela tem sua própria RLS; JOINs não bypassam RLS                |

---

## Adicionando Novas Tabelas

Ao criar uma nova tabela no sistema, **obrigatoriamente**:

1. Adicionar `school_id UUID NOT NULL REFERENCES public.schools(id)`
2. Habilitar RLS: `ALTER TABLE nova_tabela ENABLE ROW LEVEL SECURITY`
3. Criar ao menos uma policy de SELECT: 
   ```sql
   CREATE POLICY "nova_tabela_select_school" ON public.nova_tabela
     FOR SELECT USING (school_id = public.get_current_school_id());
   ```
4. Criar policies de write com restrição de role conforme necessário
5. Adicionar à lista em `validate_school_id_columns()` e `check_rls_status()`
6. Considerar adicionar trigger de auditoria se a tabela contiver dados críticos

---

## Dados do Supabase Auth

A tabela `auth.users` é gerenciada pelo Supabase e **não possui** `school_id`. O mapeamento de tenant é feito exclusivamente via `public.users.auth_id`. Isso significa que:

- Um usuário de `auth.users` pode existir sem `public.users` (edge case de signup incompleto)
- A aplicação deve sempre verificar se o usuário possui `public.users` antes de operar
- O trigger `on_auth_user_created` garante criação síncrona em `public.users`

---

## Responsabilidades por Camada

| Camada             | Responsabilidade de Isolamento                              |
|--------------------|-------------------------------------------------------------|
| PostgreSQL RLS     | Filtro hard de dados por `school_id` — última linha de defesa |
| Supabase Auth JWT  | Autenticação e identidade do usuário                        |
| Função get_current_school_id() | Bridge entre JWT e school_id              |
| Aplicação (iOS/Web) | Não enviar `school_id` no corpo das requests — é inferido  |
| Migrations         | Garantir `school_id NOT NULL` em todas as novas tabelas     |
