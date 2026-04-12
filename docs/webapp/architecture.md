# Lexend Scholar — Web App Architecture (Next.js App Router)

## Visão Geral

O web app do Lexend Scholar é construído com **Next.js 14+ App Router**, hospedado na **Vercel**, e se comunica com o banco de dados via **Supabase** (PostgreSQL + Auth). A arquitetura segue o padrão multi-tenant com isolamento por `school_id`.

---

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Framework | Next.js 14 App Router |
| Hospedagem | Vercel (Serverless + Edge) |
| Banco de Dados | Supabase (PostgreSQL) |
| Autenticação | Supabase Auth (JWT) |
| Estilo | Tailwind CSS + shadcn/ui |
| PDF | jsPDF + jspdf-autotable |
| Estado | React Context + SWR |
| Testes | Vitest + Testing Library |

---

## Estrutura de Pastas

```
webapp/
├── app/                          # Next.js App Router — páginas e layouts
│   ├── layout.tsx                # Root layout (providers, fonts)
│   ├── page.tsx                  # Redirect → /login ou /dashboard
│   ├── (auth)/                   # Route group: páginas públicas
│   │   ├── login/
│   │   │   └── page.tsx
│   │   └── reset-password/
│   │       └── page.tsx
│   └── (app)/                    # Route group: páginas protegidas
│       ├── layout.tsx            # AppShell com sidebar + topbar
│       ├── dashboard/
│       │   └── page.tsx
│       ├── alunos/
│       │   ├── page.tsx          # Lista de alunos
│       │   └── [id]/
│       │       └── page.tsx      # Perfil do aluno
│       ├── turmas/
│       │   └── page.tsx
│       ├── frequencia/
│       │   └── page.tsx
│       ├── notas/
│       │   └── page.tsx
│       ├── financeiro/
│       │   └── page.tsx
│       ├── comunicados/
│       │   └── page.tsx
│       ├── mensagens/
│       │   └── page.tsx
│       ├── eventos/
│       │   └── page.tsx
│       ├── ocorrencias/
│       │   └── page.tsx
│       ├── declaracoes/
│       │   └── page.tsx
│       └── configuracoes/
│           └── page.tsx
├── auth/                         # Helpers de autenticação
│   ├── supabase-auth.js          # Cliente Supabase + helpers de sessão
│   └── profile-router.js         # Roteamento por perfil de usuário
├── components/                   # Componentes reutilizáveis
│   ├── AppShell.html             # Shell/layout principal (protótipo HTML)
│   ├── MetricsCards.js           # Cards de métricas do dashboard
│   └── ui/                       # shadcn/ui components
└── api/                          # Vercel Serverless Functions (REST)
    ├── _middleware.js            # JWT auth middleware
    ├── _supabase.js              # Supabase service-role client
    ├── ocorrencias.js            # CRUD de ocorrências
    ├── declaracoes-pdf.js        # Emissão de declarações em PDF
    ├── documentos-aluno.js       # Gestão de documentos de aluno
    ├── comunicados.js            # Comunicados por turma
    ├── mensagens.js              # Mensagens escola-responsável
    └── eventos.js                # Eventos escolares com RSVP
```

---

## Roteamento por Perfil

O roteamento é controlado pelo middleware Next.js (`middleware.ts`) e pelo `profile-router.js`:

| Role | Acesso |
|------|--------|
| `admin` | Todos os módulos + configurações + billing |
| `secretary` | Alunos, turmas, ocorrências, declarações, comunicados, mensagens, eventos |
| `teacher` | Frequência, notas, turmas atribuídas, comunicados |
| `guardian` | Painel do responsável (somente leitura: notas, frequência, mensagens) |
| `student` | Painel do aluno (somente leitura: notas, frequência, declarações) |

---

## Middleware de Autenticação (Next.js)

```
Request
  └─► middleware.ts (Edge Runtime)
        ├── Verifica cookie supabase-auth-token
        ├── Se ausente → redirect /login
        ├── Decodifica JWT → extrai role + school_id
        └── profile-router → redirect para home correta por role
```

### Arquivo: `middleware.ts`

```typescript
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getProfileHomeRoute } from './webapp/auth/profile-router';

export async function middleware(req: NextRequest) {
  const res = NextResponse.next();
  const supabase = createMiddlewareClient({ req, res });
  const { data: { session } } = await supabase.auth.getSession();

  const { pathname } = req.nextUrl;
  const isAuthRoute = pathname.startsWith('/login') || pathname.startsWith('/reset-password');

  if (!session && !isAuthRoute) {
    return NextResponse.redirect(new URL('/login', req.url));
  }

  if (session && isAuthRoute) {
    const role = session.user.app_metadata?.role || 'teacher';
    return NextResponse.redirect(new URL(getProfileHomeRoute(role), req.url));
  }

  return res;
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|api).*)'],
};
```

---

## API Serverless (Vercel Functions)

Todas as rotas da API vivem em `webapp/api/` e seguem o padrão:

```
POST/GET /api/[recurso]
  └─► authenticateRequest (middleware JWT)
        └─► handler (lógica de negócio)
              └─► supabase (service-role, bypassa RLS para operações server-side)
```

### Padrão de Resposta

```json
// Sucesso
{ "data": [...], "total": 42, "limit": 50, "offset": 0 }

// Erro
{ "error": "Mensagem de erro", "code": "ERROR_CODE" }
```

### Endpoints Disponíveis

| Método | Rota | Descrição |
|--------|------|-----------|
| GET/POST | `/api/ocorrencias` | Listar/criar ocorrências |
| GET | `/api/ocorrencias?id=` | Buscar ocorrência por ID |
| PUT | `/api/ocorrencias` | Atualizar ocorrência |
| POST | `/api/declaracoes-pdf` | Gerar declaração em PDF (base64) |
| GET/POST | `/api/documentos-aluno` | Listar/criar documentos de aluno |
| DELETE | `/api/documentos-aluno` | Remover documento |
| GET/POST | `/api/comunicados` | Listar/criar comunicados por turma |
| GET/POST | `/api/mensagens` | Listar/criar mensagens escola-responsável |
| GET/POST | `/api/eventos` | Listar/criar eventos escolares |
| POST | `/api/eventos?action=rsvp` | Registrar RSVP em evento |

---

## Multi-Tenancy

Todos os registros no banco de dados têm `school_id`. O middleware injeta `req.user.school_id` em cada request autenticado. Toda query na API filtra por `school_id` para garantir isolamento de dados entre escolas.

---

## Variáveis de Ambiente

```env
NEXT_PUBLIC_SUPABASE_URL=https://<project>.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
SUPABASE_URL=https://<project>.supabase.co
```

---

## Fluxo de Autenticação

```
1. Usuário acessa /login
2. Preenche email + senha
3. supabase.auth.signInWithPassword()
4. Supabase retorna JWT (access_token) + refresh_token
5. Token salvo em cookie httpOnly via @supabase/auth-helpers-nextjs
6. middleware.ts lê cookie em cada request
7. Role extraída do JWT app_metadata
8. profile-router redireciona para home correta
```

---

## Diagrama de Componentes

```
┌─────────────────────────────────────────────────────┐
│                    Browser                          │
│  ┌──────────────────────────────────────────────┐   │
│  │  Next.js App Router (React Server Components)│   │
│  │  ┌──────────┐  ┌──────────┐  ┌────────────┐ │   │
│  │  │AppShell  │  │Dashboard │  │  Módulos   │ │   │
│  │  │(sidebar) │  │Metrics   │  │ (alunos,   │ │   │
│  │  │          │  │Cards     │  │  turmas…)  │ │   │
│  │  └──────────┘  └──────────┘  └────────────┘ │   │
│  └──────────────────────┬───────────────────────┘   │
└─────────────────────────┼───────────────────────────┘
                          │ fetch / SWR
                          ▼
┌─────────────────────────────────────────────────────┐
│              Vercel Edge / Serverless               │
│  ┌───────────────────────────────────────────────┐  │
│  │  middleware.ts (Edge)                         │  │
│  │  API Routes: /api/* (Node.js Serverless)      │  │
│  │   └─ _middleware.js (JWT verify)              │  │
│  └───────────────────────┬───────────────────────┘  │
└─────────────────────────┼───────────────────────────┘
                          │ supabase-js (service role)
                          ▼
┌─────────────────────────────────────────────────────┐
│                    Supabase                         │
│   PostgreSQL (RLS) + Auth + Storage                 │
└─────────────────────────────────────────────────────┘
```
