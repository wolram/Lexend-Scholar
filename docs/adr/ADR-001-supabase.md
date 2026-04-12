# ADR-001 — Backend-as-a-Service: Supabase

| Campo     | Valor                       |
|-----------|-----------------------------|
| **Status** | Aceito                     |
| **Data**   | 2026-04-12                 |
| **Autores** | Marlow Sousa              |
| **Issue**  | LS-141                     |

---

## Contexto

O Lexend Scholar precisa de uma camada de backend que ofereça, de forma integrada:

- **Banco de dados relacional** com suporte a queries complexas (frequência, notas, financeiro)
- **Autenticação** de múltiplos usuários com controle de roles (diretor, professor, secretaria, pai)
- **Storage** de arquivos (logo da escola, PDFs de boletins, contratos)
- **Realtime** para atualizações ao vivo no dashboard (frequência do dia, novos pagamentos)
- **APIs REST e GraphQL** geradas automaticamente a partir do schema

O time é pequeno (1-2 engenheiros) e não tem capacidade de manter infraestrutura de servidores própria no estágio atual.

---

## Decisão

Adotar o **Supabase** como backend-as-a-service principal, com os seguintes componentes:

| Componente         | Tecnologia Supabase                        |
|--------------------|--------------------------------------------|
| Banco de dados     | PostgreSQL 15                              |
| Autenticação       | GoTrue Auth (JWT + RLS)                    |
| Storage de arquivos | Supabase Storage (S3-compatible)          |
| Realtime           | WebSockets via Supabase Realtime           |
| Edge Functions     | Deno-based Edge Functions (webhooks, CRON) |
| API               | PostgREST (REST automático) + GraphQL via pg_graphql |

### Row Level Security (RLS)

Todo acesso ao banco será mediado por políticas RLS, garantindo isolamento entre escolas (multi-tenancy a nível de linha):

```sql
-- Exemplo: professores acessam apenas alunos da própria escola
CREATE POLICY "school_isolation" ON students
  USING (school_id = auth.jwt() ->> 'school_id');
```

---

## Alternativas Consideradas e Descartadas

| Alternativa | Motivo de Descarte |
|-------------|-------------------|
| **Firebase (Google)** | NoSQL — modelo de dados inadequado para queries relacionais complexas (frequência, notas bimestrais, financeiro). Lock-in no ecossistema Google sem possibilidade de self-host. |
| **PlanetScale** | PostgreSQL-compatível via Vitess, mas sem realtime nativo, sem auth integrado e sem storage. Exigiria múltiplos serviços externos. |
| **Neon (serverless Postgres)** | Excelente PostgreSQL serverless, mas sem autenticação, sem storage e sem realtime. Seria necessário compor 3-4 serviços adicionais. |
| **AWS Amplify** | Complexidade operacional alta para equipe pequena. Vendor lock-in forte. Custo imprevisível. |
| **Self-hosted Postgres + Auth** | Requer infraestrutura dedicada, manutenção de atualizações, backups e monitoramento — fora do escopo do estágio atual. |

---

## Consequências

### Positivas

- **Velocidade de desenvolvimento:** APIs REST geradas automaticamente a partir do schema PostgreSQL — sem escrever boilerplate de CRUD.
- **Segurança por padrão:** RLS no banco garante isolamento entre escolas sem lógica extra no backend.
- **Realtime sem infraestrutura:** dashboard ao vivo com WebSockets gerenciados pelo Supabase.
- **Migração possível:** como o banco é PostgreSQL padrão, migrar para self-host ou outra infraestrutura é tecnicamente viável.

### Negativas / Riscos

- **Vendor dependency:** dependência do Supabase como plataforma. Mitigação: uso de SQL padrão sem extensões proprietárias quando possível; manter migrations versionadas com capacidade de self-host.
- **Custo em escala:** o plano Free tem limitações de 500MB de banco e 1GB de storage. Plano Pro (US$ 25/mês) necessário quando a base de escolas crescer. Monitorar uso mensalmente.
- **Edge Functions em Deno:** ecossistema diferente de Node.js — alguns pacotes npm não são compatíveis. Considerar ao planejar integrações.

---

## Revisão

Esta decisão será reavaliada se:
- O banco ultrapassar 10GB de dados e o custo do Supabase tornar-se significativo vs. PostgreSQL gerenciado (RDS, Neon, etc.)
- Requisitos de compliance (ex: LGPD com dados sensíveis) exigirem data residency garantido em data centers brasileiros
- A equipe crescer e justificar infraestrutura própria
