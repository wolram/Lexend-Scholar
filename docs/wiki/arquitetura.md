# Arquitetura do Lexend Scholar

**Versão**: 1.0
**Última atualização**: Abril 2026
**Owner**: Marlow Sousa (CTO)

---

## Visão Geral

O Lexend Scholar é um sistema de gestão escolar SaaS multi-tenant, composto por:
- **App iOS nativo** (SwiftUI) — Primário
- **Web App** (Next.js) — Secundário / Complementar
- **API Backend** (Supabase + Edge Functions)
- **Banco de dados** (PostgreSQL via Supabase)

O sistema atende múltiplos perfis: Diretor, Professor, Secretaria e Responsável, com controle de acesso baseado em roles (RBAC) e isolamento multi-tenant por `school_id`.

---

## Stack Tecnológico

### Frontend iOS
| Tecnologia | Versão | Função |
|---|---|---|
| Swift | 5.10+ | Linguagem principal |
| SwiftUI | 5.0+ | Framework de UI |
| XcodeGen | 2.x | Geração de projeto Xcode |
| SwiftLint | 0.54+ | Linting e style guide |
| Supabase Swift SDK | 2.x | Autenticação e dados |
| Core Data | — | Persistência local (offline) |
| CloudKit | — | Sincronização iCloud (futuro) |

### Frontend Web
| Tecnologia | Versão | Função |
|---|---|---|
| Next.js | 14+ (App Router) | Framework React |
| TypeScript | 5.x | Type safety |
| Tailwind CSS | 3.x | Estilização |
| Supabase JS SDK | 2.x | Autenticação e dados |
| Shadcn/ui | — | Componentes base |

### Backend e Infraestrutura
| Tecnologia | Função |
|---|---|
| Supabase | BaaS: PostgreSQL, Auth, Storage, Edge Functions |
| Supabase Edge Functions (Deno) | Lógica de negócio server-side, webhooks |
| Vercel | Hosting do Next.js, deploy automático |
| Cloudflare Workers | Webhook middleware (Crisp → Linear) |
| Stripe | Processamento de pagamentos e assinaturas |
| NFE.io | Emissão de NFS-e automatizada |
| Better Uptime | Monitoramento de uptime |
| Sentry | Error tracking |

---

## Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                         CLIENTES                            │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   │
│  │   App iOS    │   │   Web App    │   │ App Resp.    │   │
│  │  (SwiftUI)   │   │  (Next.js)   │   │   (iOS/Web)  │   │
│  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘   │
└─────────│─────────────────│─────────────────│─────────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │ HTTPS / WebSocket
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     SUPABASE (BaaS)                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  Auth API   │  │  REST API   │  │   Edge Functions    │ │
│  │  (JWT/RLS)  │  │  (PostgREST)│  │   (Deno/TypeScript) │ │
│  └─────────────┘  └──────┬──────┘  └──────────┬──────────┘ │
│                          │                    │             │
│                   ┌──────▼──────────────────▼──────┐       │
│                   │         PostgreSQL              │       │
│                   │   (Row Level Security + RLS)   │       │
│                   └──────────────────────────────-─┘       │
└─────────────────────────────────────────────────────────────┘
                            │
          ┌─────────────────┼──────────────────┐
          │                 │                  │
          ▼                 ▼                  ▼
   ┌────────────┐   ┌──────────────┐   ┌────────────────┐
   │   Stripe   │   │   NFE.io     │   │    Crisp       │
   │ (Billing)  │   │  (NFS-e)     │   │  (Suporte)     │
   └────────────┘   └──────────────┘   └────────────────┘
```

---

## Modelo Multi-Tenant

O Lexend Scholar é multi-tenant com isolamento por `school_id`. Cada escola é um tenant.

### Estratégia de isolamento: Row-Level Security (RLS)

Optamos por **shared database, shared schema** com RLS no PostgreSQL. Isso significa:
- Uma única instância de banco de dados compartilhada entre todas as escolas
- Cada tabela tem uma coluna `school_id` que identifica o tenant
- Políticas de RLS garantem que cada usuário só vê os dados da sua escola

**Por que não schema-per-tenant?**
- Muito complexo para gerenciar em early stage
- Supabase suporta RLS nativamente com excelente performance
- Schema-per-tenant considerado quando ultrapassarmos 1.000 escolas

### Exemplo de política RLS

```sql
-- Política: professor só vê alunos da sua escola
CREATE POLICY "Teachers can view students in their school"
ON students
FOR SELECT
USING (
  school_id = (
    SELECT school_id FROM school_users
    WHERE user_id = auth.uid()
  )
);

-- Política: responsável só vê alunos que ele é responsável
CREATE POLICY "Parents can view their children"
ON students
FOR SELECT
USING (
  id IN (
    SELECT student_id FROM student_guardians
    WHERE guardian_id = auth.uid()
  )
);
```

---

## Autenticação e Autorização

### Autenticação (Supabase Auth)
- **Email + Senha**: Padrão para todos os usuários
- **Magic Link**: Para responsáveis (menor fricção)
- **JWT tokens**: Stateless, expiração em 1 hora, refresh token em 7 dias
- **RLS**: Automático via `auth.uid()` nas políticas

### Roles (RBAC)
```typescript
enum UserRole {
  SCHOOL_ADMIN = 'school_admin',    // Diretor — acesso total na escola
  TEACHER = 'teacher',              // Professor — acesso ao seu conteúdo
  SECRETARY = 'secretary',          // Secretaria — acesso a dados admin
  GUARDIAN = 'guardian',            // Responsável — acesso aos seus filhos
  SUPER_ADMIN = 'super_admin'       // Time Lexend Scholar — acesso cross-tenant
}
```

Roles são armazenados na tabela `school_users` e verificados via RLS.

---

## Modelo de Dados — Entidades Principais

```
schools
  ├── school_users (membros da escola)
  │     └── users (Supabase Auth)
  ├── students (alunos)
  │     ├── student_guardians (responsáveis)
  │     ├── enrollments (matrículas por ano letivo)
  │     └── student_health (dados de saúde — acesso restrito)
  ├── classes (turmas)
  │     ├── class_teachers (professores da turma)
  │     └── class_students (alunos da turma)
  ├── attendance_records (frequência)
  ├── assessments (avaliações)
  │     └── grades (notas)
  ├── documents (documentos emitidos)
  ├── invoices (cobranças de mensalidade)
  │     └── payments (pagamentos confirmados)
  └── notifications (notificações enviadas)
```

Para o schema completo com colunas e tipos, ver [banco-schema.md](banco-schema.md).

---

## Arquitetura iOS

### Padrão Arquitetural: MVVM + Clean Architecture

```
LexendScholar/
├── App/
│   ├── LexendScholarApp.swift      # Entry point SwiftUI
│   └── AppDelegate.swift
├── Core/
│   ├── Network/                    # Supabase client, API calls
│   ├── Persistence/                # Core Data stack, offline storage
│   ├── Auth/                       # Autenticação, tokens
│   └── Extensions/                 # Swift extensions utilitárias
├── Features/
│   ├── Dashboard/                  # Dashboard do diretor
│   ├── Attendance/                 # Frequência
│   ├── Grades/                     # Notas e avaliações
│   ├── Students/                   # Cadastro e perfil de alunos
│   ├── Documents/                  # Emissão de documentos
│   ├── Financial/                  # Módulo financeiro
│   └── Profile/                    # Perfil e configurações
├── DesignSystem/
│   ├── SchoolPalette.swift         # Cores
│   ├── Typography.swift            # Tipografia
│   └── Components/                 # Componentes reutilizáveis
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

### Offline-First

O app iOS funciona offline via Core Data:
1. Todos os dados são sincronizados localmente
2. Operações de escrita são enfileiradas localmente
3. Sync automático quando a conexão retorna
4. Conflitos resolvidos por `last-write-wins` com timestamp do servidor

---

## Decisões Técnicas Principais

### Por que Supabase e não Firebase?
- SQL é mais adequado para dados estruturados escolares (relações complexas)
- RLS nativo é superior ao Firestore Rules para multi-tenant
- Open source — sem vendor lock-in total
- Supabase Edge Functions são simples para lógica de backend

### Por que Next.js e não SvelteKit/Remix?
- Ecossistema React maior (componentes disponíveis, bibliotecas)
- App Router v2 com Server Components é excelente para performance
- Vercel (criadora do Next.js) oferece deploy integrado

### Por que iOS-first e não React Native / Flutter?
- Performance nativa superior para app de gestão com muitas listas
- Acesso a APIs nativas (Core Data, APNS, Biometria)
- SwiftUI é maduro o suficiente para produto de qualidade
- Detalhes em: [docs/blog/04-ios-gestao.md](../blog/04-ios-gestao.md)

---

## Monitoramento e Observabilidade

| Camada | Ferramenta | O que monitora |
|---|---|---|
| Frontend Web | Vercel Analytics | Core Web Vitals, traffic |
| Frontend iOS | Crashlytics | Crashes, ANRs |
| Backend | Supabase Logs | Queries, auth, storage |
| Errors | Sentry | Exceções em produção (web + iOS) |
| Uptime | Better Uptime | Disponibilidade da API e web |
| Pagamentos | Stripe Dashboard | Webhooks, falhas de pagamento |

---

## Limites e Escalabilidade

| Métrica | Atual (Supabase Free/Pro) | Meta Q2 2026 |
|---|---|---|
| Conexões simultâneas ao banco | 60 | 200 (upgrade) |
| Tamanho do banco | 8 GB | 100 GB |
| Edge Functions invocações/mês | 500k | 2M |
| Storage (documentos) | 100 GB | 1 TB |
| API requests/dia | Ilimitado (rate limited) | — |

Quando escalar:
- **Banco de dados**: Upgrade de plano Supabase ou migrar para RDS dedicado
- **Reads**: Implementar read replicas no Supabase (disponível no Pro)
- **Edge Functions**: Migrar para Cloudflare Workers se necessário (Cold start melhor)
