# Audit Log — Lexend Scholar

## Visão Geral

O Lexend Scholar mantém um registro imutável de todas as ações críticas realizadas em tabelas sensíveis. O `audit_log` captura automaticamente INSERT, UPDATE e DELETE via triggers PostgreSQL, sem necessidade de lógica na camada de aplicação.

---

## Estrutura da Tabela

```sql
public.audit_log (
  id          UUID        PRIMARY KEY,
  school_id   UUID        NOT NULL,   -- tenant isolamento
  user_id     UUID,                   -- public.users.id (nullable se usuário deletado)
  auth_id     UUID,                   -- auth.users.id snapshot no momento da ação
  action      TEXT,                   -- 'INSERT' | 'UPDATE' | 'DELETE'
  table_name  TEXT,                   -- nome da tabela afetada
  record_id   UUID,                   -- id do registro afetado
  old_values  JSONB,                  -- snapshot antes da mudança (NULL em INSERT)
  new_values  JSONB,                  -- snapshot após a mudança (NULL em DELETE)
  ip_address  INET,                   -- opcional, preenchido pela aplicação
  user_agent  TEXT,                   -- opcional
  created_at  TIMESTAMPTZ             -- timestamp imutável
)
```

---

## Tabelas Auditadas

| Tabela                      | INSERT | UPDATE | DELETE |
|-----------------------------|--------|--------|--------|
| `students`                  | X      | X      | X      |
| `users`                     | X      | X      | X      |
| `student_class_enrollments` | X      | X      | X      |
| `financial_records`         | X      | X      | X      |
| `grade_records`             | X      | X      | X      |
| `attendance_records`        | X      | X      | X      |

---

## Acesso ao Audit Log

### Permissão
Somente usuários com `role = 'admin'` da escola podem consultar o audit log. Isso é enforçado via RLS:

```sql
CREATE POLICY "audit_log_select_admin" ON public.audit_log
  FOR SELECT USING (
    school_id = public.get_current_school_id()
    AND public.get_current_user_role() = 'admin'
  );
```

Nenhum usuário final pode inserir, atualizar ou deletar registros do audit_log diretamente. Apenas a função trigger `log_audit_action()` (SECURITY DEFINER) pode inserir.

---

## Consultas Úteis

### Todas as ações de um usuário específico
```sql
SELECT
  al.created_at,
  al.action,
  al.table_name,
  al.record_id,
  u.full_name AS usuario,
  u.role
FROM public.audit_log al
LEFT JOIN public.users u ON u.id = al.user_id
WHERE al.school_id = '<school_id>'
  AND al.user_id   = '<user_id>'
ORDER BY al.created_at DESC
LIMIT 100;
```

### Histórico completo de um registro específico
```sql
SELECT
  al.created_at,
  al.action,
  al.old_values,
  al.new_values,
  u.full_name AS alterado_por
FROM public.audit_log al
LEFT JOIN public.users u ON u.id = al.user_id
WHERE al.school_id  = '<school_id>'
  AND al.table_name = 'students'
  AND al.record_id  = '<student_id>'
ORDER BY al.created_at ASC;
```

### Todas as deleções nas últimas 24 horas
```sql
SELECT
  al.created_at,
  al.table_name,
  al.record_id,
  al.old_values,
  u.full_name AS deletado_por
FROM public.audit_log al
LEFT JOIN public.users u ON u.id = al.user_id
WHERE al.school_id  = '<school_id>'
  AND al.action     = 'DELETE'
  AND al.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY al.created_at DESC;
```

### Alterações em notas (grade_records) de um aluno
```sql
SELECT
  al.created_at,
  al.action,
  al.old_values->>'grade'  AS nota_anterior,
  al.new_values->>'grade'  AS nota_nova,
  u.full_name              AS alterado_por
FROM public.audit_log al
LEFT JOIN public.users u ON u.id = al.user_id
WHERE al.school_id  = '<school_id>'
  AND al.table_name = 'grade_records'
  AND (al.old_values->>'student_id' = '<student_id>'
    OR al.new_values->>'student_id' = '<student_id>')
ORDER BY al.created_at DESC;
```

### Atividade financeira suspeita (múltiplas alterações em curto período)
```sql
SELECT
  al.user_id,
  u.full_name,
  COUNT(*) AS total_acoes,
  MIN(al.created_at) AS primeira_acao,
  MAX(al.created_at) AS ultima_acao
FROM public.audit_log al
LEFT JOIN public.users u ON u.id = al.user_id
WHERE al.school_id  = '<school_id>'
  AND al.table_name = 'financial_records'
  AND al.created_at >= NOW() - INTERVAL '1 hour'
GROUP BY al.user_id, u.full_name
HAVING COUNT(*) > 10
ORDER BY total_acoes DESC;
```

---

## Retenção e Arquivamento

- O audit_log não possui TTL automático — os dados são retidos indefinidamente.
- Para escolas com alto volume, recomenda-se particionar por `created_at` (range partitioning mensal).
- Exportação para cold storage pode ser feita com:

```sql
COPY (
  SELECT * FROM public.audit_log
  WHERE school_id = '<school_id>'
    AND created_at < NOW() - INTERVAL '1 year'
) TO '/tmp/audit_log_archive.csv' CSV HEADER;
```

---

## Importante

- O audit_log é **append-only** por design: não há política UPDATE ou DELETE para usuários finais.
- O campo `old_values` e `new_values` usa JSONB — consulte campos específicos com `->` e `->>`.
- Em caso de usuário deletado, `user_id` pode ser NULL, mas `auth_id` preserva o UUID original do Supabase Auth.
