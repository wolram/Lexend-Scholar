# LS-6 — Configurar Políticas de RLS por Role

## Visão Geral

Além do isolamento por tenant (`school_id`), o RLS do Lexend Scholar implementa controle de acesso granular baseado no `role` do usuário. Os roles são: `admin`, `teacher`, `secretary`, `guardian` e `student`.

O `role` é injetado no JWT via hook de token customizado (ver `docs/infra/rls-tenant.md`).

## Hierarquia de Permissões

| Tabela              | admin | teacher | secretary | guardian | student |
|---------------------|-------|---------|-----------|----------|---------|
| schools             | RW    | R       | R         | —        | —       |
| users               | RW    | R(self) | R         | —        | —       |
| students            | RW    | R       | RW        | R(filhos)| R(self) |
| classes             | RW    | R       | RW        | —        | R       |
| subjects            | RW    | R       | RW        | —        | R       |
| attendance_records  | RW    | RW      | R         | R(filhos)| R(self) |
| grades              | RW    | RW      | R         | R(filhos)| R(self) |
| invoices            | RW    | —       | RW        | R(filhos)| —       |
| payments            | RW    | —       | RW        | R(filhos)| —       |
| notifications       | RW    | RW      | RW        | R(self)  | R(self) |

**R** = Read, **W** = Write (INSERT/UPDATE/DELETE), **—** = sem acesso

## Policies por Tabela

### Tabela: users

```sql
-- Admin: acesso total ao tenant
CREATE POLICY "users: admin full access"
  ON users FOR ALL
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'admin'
  );

-- Teacher/Secretary: leitura de todos usuários do tenant
CREATE POLICY "users: staff read"
  ON users FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() IN ('teacher', 'secretary')
  );

-- Qualquer usuário autenticado: leitura do próprio perfil
CREATE POLICY "users: self read"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Qualquer usuário autenticado: atualizar próprio perfil (campos limitados)
CREATE POLICY "users: self update"
  ON users FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND school_id = auth.school_id()
    -- role e school_id não podem ser alterados pelo próprio usuário
  );
```

### Tabela: students

```sql
-- Admin e Secretary: acesso total
CREATE POLICY "students: admin secretary full"
  ON students FOR ALL
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() IN ('admin', 'secretary')
  );

-- Teacher: leitura de todos alunos do tenant
CREATE POLICY "students: teacher read"
  ON students FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'teacher'
  );

-- Guardian: leitura apenas dos próprios filhos
CREATE POLICY "students: guardian read own children"
  ON students FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'guardian'
    AND id IN (
      SELECT student_id FROM student_guardians
      WHERE guardian_id = auth.uid()
    )
  );

-- Student: leitura do próprio perfil
CREATE POLICY "students: student read self"
  ON students FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'student'
    AND user_id = auth.uid()
  );
```

### Tabela: attendance_records

```sql
-- Admin: acesso total
CREATE POLICY "attendance: admin full"
  ON attendance_records FOR ALL
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'admin'
  );

-- Teacher: leitura e escrita nas turmas que leciona
CREATE POLICY "attendance: teacher rw own classes"
  ON attendance_records FOR ALL
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'teacher'
    AND class_id IN (
      SELECT id FROM classes WHERE teacher_id = auth.uid()
    )
  );

-- Secretary: somente leitura
CREATE POLICY "attendance: secretary read"
  ON attendance_records FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'secretary'
  );

-- Guardian: leitura dos filhos
CREATE POLICY "attendance: guardian read children"
  ON attendance_records FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'guardian'
    AND student_id IN (
      SELECT student_id FROM student_guardians WHERE guardian_id = auth.uid()
    )
  );

-- Student: leitura da própria frequência
CREATE POLICY "attendance: student read self"
  ON attendance_records FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'student'
    AND student_id IN (
      SELECT id FROM students WHERE user_id = auth.uid()
    )
  );
```

### Tabela: grades

```sql
-- Admin: acesso total
CREATE POLICY "grades: admin full"
  ON grades FOR ALL
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'admin'
  );

-- Teacher: RW nas disciplinas que leciona
CREATE POLICY "grades: teacher rw own subjects"
  ON grades FOR ALL
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'teacher'
    AND subject_id IN (
      SELECT id FROM subjects WHERE teacher_id = auth.uid()
    )
  );

-- Secretary: somente leitura
CREATE POLICY "grades: secretary read"
  ON grades FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'secretary'
  );

-- Guardian: leitura dos filhos
CREATE POLICY "grades: guardian read children"
  ON grades FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'guardian'
    AND student_id IN (
      SELECT student_id FROM student_guardians WHERE guardian_id = auth.uid()
    )
  );

-- Student: leitura das próprias notas
CREATE POLICY "grades: student read self"
  ON grades FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'student'
    AND student_id IN (
      SELECT id FROM students WHERE user_id = auth.uid()
    )
  );
```

### Tabela: invoices e payments

```sql
-- Admin e Secretary: acesso total
CREATE POLICY "invoices: admin secretary full"
  ON invoices FOR ALL
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() IN ('admin', 'secretary')
  );

-- Guardian: leitura das faturas dos filhos
CREATE POLICY "invoices: guardian read children"
  ON invoices FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'guardian'
    AND student_id IN (
      SELECT student_id FROM student_guardians WHERE guardian_id = auth.uid()
    )
  );

-- Payments segue a mesma regra via FK de invoice
CREATE POLICY "payments: admin secretary full"
  ON payments FOR ALL
  TO authenticated
  USING (
    invoice_id IN (
      SELECT id FROM invoices
      WHERE school_id = auth.school_id()
      AND auth.user_role() IN ('admin', 'secretary')
    )
  );
```

### Tabela: notifications

```sql
-- Admin: acesso total ao tenant
CREATE POLICY "notifications: admin full"
  ON notifications FOR ALL
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND auth.user_role() = 'admin'
  );

-- Staff: pode criar notificações
CREATE POLICY "notifications: staff insert"
  ON notifications FOR INSERT
  TO authenticated
  WITH CHECK (
    school_id = auth.school_id()
    AND auth.user_role() IN ('teacher', 'secretary')
  );

-- Qualquer usuário: leitura das próprias notificações
CREATE POLICY "notifications: self read"
  ON notifications FOR SELECT
  TO authenticated
  USING (
    school_id = auth.school_id()
    AND user_id = auth.uid()
  );

-- Qualquer usuário: marcar próprias notificações como lidas
CREATE POLICY "notifications: self update read status"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

## Migration

Salvar em `supabase/migrations/20240101000003_rls_roles.sql` com todas as policies acima.

## Testes de RLS por Role

```sql
-- Simular autenticação como teacher
SET LOCAL request.jwt.claims = '{
  "sub": "<teacher-uuid>",
  "school_id": "<school-uuid>",
  "user_role": "teacher"
}';

-- Teacher deve ver alunos mas não faturas
SELECT count(*) FROM students;    -- OK
SELECT count(*) FROM invoices;    -- Deve retornar 0 (sem acesso)

-- Simular guardian
SET LOCAL request.jwt.claims = '{
  "sub": "<guardian-uuid>",
  "school_id": "<school-uuid>",
  "user_role": "guardian"
}';
SELECT count(*) FROM students;    -- Só deve retornar os filhos
```

## Referências

- `docs/infra/rls-tenant.md` — isolamento por tenant
- `supabase/migrations/` — migrations SQL
- [Supabase RLS Policies](https://supabase.com/docs/guides/auth/row-level-security)
