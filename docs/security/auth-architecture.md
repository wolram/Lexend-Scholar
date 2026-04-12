# Arquitetura de Autenticação — Lexend Scholar

## Visão Geral

O Lexend Scholar usa o **Supabase Auth** como provedor de autenticação. Cada usuário autenticado é mapeado automaticamente para um registro em `public.users`, que carrega o `school_id` e o `role` do usuário.

---

## Fluxo Completo de Autenticação

```
Cliente (app iOS / webapp)
        │
        │  1. signInWithPassword / signInWithMagicLink
        ▼
   Supabase Auth
   (auth.users)
        │
        │  2. JWT emitido com sub = auth.uid()
        │
        │  3. Trigger on_auth_user_created (no signup)
        │     → INSERT em public.users (auth_id, school_id, role, email)
        ▼
   public.users
        │
        │  4. Cada request subsequente inclui JWT no header
        │     Authorization: Bearer <jwt>
        │
        │  5. RLS policies chamam:
        │     - get_current_school_id() → SELECT school_id FROM users WHERE auth_id = auth.uid()
        │     - get_current_user_role() → SELECT role FROM users WHERE auth_id = auth.uid()
        ▼
   Dados filtrados por school_id + role
```

---

## Componentes

### `auth.users` (Supabase Auth interno)
- Gerenciado exclusivamente pelo Supabase Auth
- Contém: `id` (UUID), `email`, `raw_user_meta_data`, timestamps
- Não deve ser acessado diretamente pela aplicação

### `public.users` (tabela da aplicação)
- Espelho do usuário com dados de negócio
- Colunas-chave: `auth_id`, `school_id`, `role`, `email`, `full_name`
- Criado automaticamente via trigger `on_auth_user_created`

### Trigger `on_auth_user_created`
- Disparado após INSERT em `auth.users`
- Lê `raw_user_meta_data` para extrair `school_id`, `role`, `full_name`
- Faz upsert em `public.users`

---

## Roles do Sistema

| Role        | Descrição                                  | Acesso                                    |
|-------------|--------------------------------------------|-------------------------------------------|
| `admin`     | Diretor da escola                          | Leitura/escrita total na escola           |
| `secretary` | Secretaria                                 | Alunos, matrículas, financeiro            |
| `teacher`   | Professor / Coordenador                    | Turmas, notas, frequência                 |
| `guardian`  | Responsável pelo aluno                     | Dados do(s) filho(s) apenas               |
| `student`   | Aluno                                      | Próprios dados                            |

> Os roles acima são mapeados do `role_type` enum definido no schema para as políticas RLS.

---

## Criação de Usuários

### Via SDK do Supabase (signup)
```typescript
const { data, error } = await supabase.auth.signUp({
  email: 'professor@escola.com',
  password: 'senha-segura',
  options: {
    data: {
      school_id: 'uuid-da-escola',
      role: 'teacher',
      full_name: 'João Silva',
    }
  }
})
```

### Via Admin API (criação pelo painel)
```typescript
const { data, error } = await supabase.auth.admin.createUser({
  email: 'diretor@escola.com',
  password: 'senha-temporaria',
  user_metadata: {
    school_id: 'uuid-da-escola',
    role: 'admin',
    full_name: 'Maria Santos',
  },
  email_confirm: true,
})
```

---

## Funções Helper para RLS

### `get_current_school_id() → UUID`
Retorna o `school_id` do usuário autenticado. Usada em todas as políticas RLS para isolar dados por tenant.

### `get_current_user_role() → TEXT`
Retorna o role do usuário autenticado. Usada em políticas que diferenciam permissões por role.

### `get_current_user_id() → UUID`
Retorna o `id` interno em `public.users` do usuário autenticado.

---

## Segurança do JWT

- O Supabase assina todos os JWTs com `JWT_SECRET`
- O `auth.uid()` no PostgreSQL extrai o `sub` do JWT automaticamente
- As funções helper são `SECURITY DEFINER` para evitar escalada de privilégios
- `SET search_path = public` em todas as funções para prevenir ataques de search_path

---

## Magic Link (Responsáveis)

Para responsáveis (guardiões) que não possuem senha:

```typescript
const { error } = await supabase.auth.signInWithOtp({
  email: 'responsavel@email.com',
  options: {
    data: {
      school_id: 'uuid-da-escola',
      role: 'guardian',
    }
  }
})
```

---

## Fluxo de Logout

```typescript
await supabase.auth.signOut()
// Invalida o JWT localmente; o refresh token é revogado no Supabase
```
