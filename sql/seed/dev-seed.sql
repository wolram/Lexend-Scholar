-- ============================================================
-- LS-81 — Realistic dev seed data for Lexend Scholar
-- Creates one demo school with realistic Brazilian data.
-- Safe to run multiple times — uses INSERT ... ON CONFLICT DO NOTHING.
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- Fixed UUIDs for repeatability
-- ──────────────────────────────────────────────────────────────
\set school_id      '\'a1b2c3d4-0000-0000-0000-000000000001\''
\set year_2025      '\'a1b2c3d4-0000-0000-0000-000000000010\''
\set period_bim1    '\'a1b2c3d4-0000-0000-0000-000000000020\''
\set period_bim2    '\'a1b2c3d4-0000-0000-0000-000000000021\''
\set period_bim3    '\'a1b2c3d4-0000-0000-0000-000000000022\''
\set period_bim4    '\'a1b2c3d4-0000-0000-0000-000000000023\''
\set grade_6ano     '\'a1b2c3d4-0000-0000-0000-000000000030\''
\set grade_7ano     '\'a1b2c3d4-0000-0000-0000-000000000031\''
\set grade_8ano     '\'a1b2c3d4-0000-0000-0000-000000000032\''
\set class_1a       '\'a1b2c3d4-0000-0000-0000-000000000040\''
\set class_2b       '\'a1b2c3d4-0000-0000-0000-000000000041\''
\set class_3c       '\'a1b2c3d4-0000-0000-0000-000000000042\''
\set admin_user     '\'a1b2c3d4-0000-0000-0000-000000000050\''
\set teacher_mat    '\'a1b2c3d4-0000-0000-0000-000000000051\''
\set teacher_port   '\'a1b2c3d4-0000-0000-0000-000000000052\''
\set teacher_hist   '\'a1b2c3d4-0000-0000-0000-000000000053\''
\set teacher_cien   '\'a1b2c3d4-0000-0000-0000-000000000054\''
\set teacher_geo    '\'a1b2c3d4-0000-0000-0000-000000000055\''
\set secretary      '\'a1b2c3d4-0000-0000-0000-000000000056\''
\set subj_mat       '\'a1b2c3d4-0000-0000-0000-000000000060\''
\set subj_port      '\'a1b2c3d4-0000-0000-0000-000000000061\''
\set subj_hist      '\'a1b2c3d4-0000-0000-0000-000000000062\''
\set subj_geo       '\'a1b2c3d4-0000-0000-0000-000000000063\''
\set subj_cien      '\'a1b2c3d4-0000-0000-0000-000000000064\''
\set subj_ing       '\'a1b2c3d4-0000-0000-0000-000000000065\''
\set subj_ef        '\'a1b2c3d4-0000-0000-0000-000000000066\''
\set subj_artes     '\'a1b2c3d4-0000-0000-0000-000000000067\''

BEGIN;

-- ──────────────────────────────────────────────────────────────
-- ESCOLA
-- ──────────────────────────────────────────────────────────────
INSERT INTO schools (id, name, cnpj, email, phone, address, city, state, zip_code, plan, max_students, subscription_status)
VALUES (
  :school_id,
  'Escola Estadual João Paulo II',
  '12.345.678/0001-99',
  'contato@joaopaulo2.edu.br',
  '(11) 3456-7890',
  'Av. João Paulo II, 450',
  'São Paulo', 'SP', '04551-060',
  'pro', 500, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- USUÁRIOS (equipe)
-- ──────────────────────────────────────────────────────────────
INSERT INTO users (id, school_id, email, full_name, role, active) VALUES
  (:admin_user,  :school_id, 'diretora@joaopaulo2.edu.br',       'Dra. Maria Aparecida Souza',   'admin',     true),
  (:teacher_mat, :school_id, 'prof.matematica@joaopaulo2.edu.br','Prof. Carlos Eduardo Lima',    'teacher',   true),
  (:teacher_port,:school_id, 'prof.portugues@joaopaulo2.edu.br', 'Profa. Ana Beatriz Ferreira',  'teacher',   true),
  (:teacher_hist,:school_id, 'prof.historia@joaopaulo2.edu.br',  'Prof. Ricardo Mendes',         'teacher',   true),
  (:teacher_cien,:school_id, 'prof.ciencias@joaopaulo2.edu.br',  'Profa. Juliana Costa',         'teacher',   true),
  (:teacher_geo, :school_id, 'prof.geografia@joaopaulo2.edu.br', 'Prof. Marcos Vinícius Alves',  'teacher',   true),
  (:secretary,   :school_id, 'secretaria@joaopaulo2.edu.br',     'Sra. Fernanda Oliveira',       'secretary', true)
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- ANO LETIVO
-- ──────────────────────────────────────────────────────────────
INSERT INTO academic_years (id, school_id, name, start_date, end_date, active)
VALUES (:year_2025, :school_id, '2025', '2025-02-03', '2025-12-12', true)
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- BIMESTRES
-- ──────────────────────────────────────────────────────────────
INSERT INTO academic_periods (id, school_id, academic_year_id, name, start_date, end_date) VALUES
  (:period_bim1, :school_id, :year_2025, '1º Bimestre', '2025-02-03', '2025-04-11'),
  (:period_bim2, :school_id, :year_2025, '2º Bimestre', '2025-04-14', '2025-06-27'),
  (:period_bim3, :school_id, :year_2025, '3º Bimestre', '2025-07-28', '2025-09-26'),
  (:period_bim4, :school_id, :year_2025, '4º Bimestre', '2025-09-29', '2025-12-12')
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- SÉRIES — 6º, 7º, 8º ano (Ensino Fundamental II)
-- ──────────────────────────────────────────────────────────────
INSERT INTO grades (id, school_id, name, level) VALUES
  (:grade_6ano, :school_id, '6º Ano', 'fundamental'),
  (:grade_7ano, :school_id, '7º Ano', 'fundamental'),
  (:grade_8ano, :school_id, '8º Ano', 'fundamental')
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- TURMAS: 1A (6º ano), 2B (7º ano), 3C (8º ano)
-- ──────────────────────────────────────────────────────────────
INSERT INTO classes (id, school_id, grade_id, academic_year_id, name, teacher_id, max_students) VALUES
  (:class_1a, :school_id, :grade_6ano, :year_2025, '1A', :teacher_mat,  35),
  (:class_2b, :school_id, :grade_7ano, :year_2025, '2B', :teacher_port, 33),
  (:class_3c, :school_id, :grade_8ano, :year_2025, '3C', :teacher_hist, 30)
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- DISCIPLINAS
-- ──────────────────────────────────────────────────────────────
INSERT INTO subjects (id, school_id, name, code) VALUES
  (:subj_mat,  :school_id, 'Matemática',        'MAT'),
  (:subj_port, :school_id, 'Língua Portuguesa',  'PORT'),
  (:subj_hist, :school_id, 'História',           'HIST'),
  (:subj_geo,  :school_id, 'Geografia',          'GEO'),
  (:subj_cien, :school_id, 'Ciências',           'CIEN'),
  (:subj_ing,  :school_id, 'Língua Inglesa',     'ING'),
  (:subj_ef,   :school_id, 'Educação Física',    'EF'),
  (:subj_artes,:school_id, 'Arte',               'ART')
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- DISCIPLINAS POR TURMA
-- ──────────────────────────────────────────────────────────────
INSERT INTO class_subjects (class_id, subject_id, teacher_id, weekly_hours) VALUES
  -- 1A (6º ano)
  (:class_1a, :subj_mat,  :teacher_mat,  5),
  (:class_1a, :subj_port, :teacher_port, 5),
  (:class_1a, :subj_hist, :teacher_hist, 2),
  (:class_1a, :subj_geo,  :teacher_geo,  2),
  (:class_1a, :subj_cien, :teacher_cien, 3),
  (:class_1a, :subj_ing,  :teacher_port, 2),
  -- 2B (7º ano)
  (:class_2b, :subj_mat,  :teacher_mat,  5),
  (:class_2b, :subj_port, :teacher_port, 5),
  (:class_2b, :subj_hist, :teacher_hist, 2),
  (:class_2b, :subj_geo,  :teacher_geo,  2),
  (:class_2b, :subj_cien, :teacher_cien, 3),
  -- 3C (8º ano)
  (:class_3c, :subj_mat,  :teacher_mat,  5),
  (:class_3c, :subj_port, :teacher_port, 4),
  (:class_3c, :subj_hist, :teacher_hist, 3),
  (:class_3c, :subj_cien, :teacher_cien, 3)
ON CONFLICT (class_id, subject_id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- 10 ALUNOS COM NOMES BRASILEIROS REALISTAS + RESPONSÁVEIS
-- Turma 1A: alunos 1-4; 2B: alunos 5-7; 3C: alunos 8-10
-- ──────────────────────────────────────────────────────────────
INSERT INTO students (school_id, enrollment_code, full_name, birth_date, gender, email, phone, city, state, active) VALUES
  -- 1A (6º ano) — nascidos ~2013
  (:school_id, '2025001', 'Ana Paula Rodrigues',       '2013-03-12', 'F', 'ana.rodrigues@aluno.jp2.edu.br',    '(11)98000-0001', 'São Paulo',  'SP', true),
  (:school_id, '2025002', 'Bruno Henrique Santos',     '2013-07-24', 'M', 'bruno.santos@aluno.jp2.edu.br',     '(11)98000-0002', 'São Paulo',  'SP', true),
  (:school_id, '2025003', 'Carla Mendonça Lima',       '2013-01-05', 'F', 'carla.lima@aluno.jp2.edu.br',       '(11)98000-0003', 'São Paulo',  'SP', true),
  (:school_id, '2025004', 'Daniel Ferreira Costa',     '2013-11-30', 'M', 'daniel.costa@aluno.jp2.edu.br',     '(11)98000-0004', 'Guarulhos',  'SP', true),
  -- 2B (7º ano) — nascidos ~2012
  (:school_id, '2024001', 'Eduarda Alves Pereira',     '2012-06-18', 'F', 'eduarda.pereira@aluno.jp2.edu.br',  '(11)98000-0005', 'São Paulo',  'SP', true),
  (:school_id, '2024002', 'Felipe Gomes Almeida',      '2012-09-02', 'M', 'felipe.almeida@aluno.jp2.edu.br',   '(11)98000-0006', 'São Paulo',  'SP', true),
  (:school_id, '2024003', 'Gabriela Nunes Carvalho',   '2012-04-20', 'F', 'gabriela.carvalho@aluno.jp2.edu.br','(11)98000-0007', 'Osasco',     'SP', true),
  -- 3C (8º ano) — nascidos ~2011
  (:school_id, '2023001', 'Henrique Souza Melo',       '2011-12-15', 'M', 'henrique.melo@aluno.jp2.edu.br',    '(11)98000-0008', 'São Paulo',  'SP', true),
  (:school_id, '2023002', 'Isabela Martins Rocha',     '2011-02-28', 'F', 'isabela.rocha@aluno.jp2.edu.br',    '(11)98000-0009', 'São Paulo',  'SP', true),
  (:school_id, '2023003', 'João Pedro Oliveira',       '2011-08-09', 'M', 'joao.oliveira@aluno.jp2.edu.br',    '(11)98000-0010', 'Mauá',       'SP', true)
ON CONFLICT (school_id, enrollment_code) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- RESPONSÁVEIS (guardians)
-- ──────────────────────────────────────────────────────────────
INSERT INTO guardians (id, school_id, full_name, cpf, email, phone, relation) VALUES
  ('a1b2c3d4-0000-0000-0001-000000000001'::UUID, :school_id, 'José Rodrigues da Silva',   '123.456.789-01', 'jose.rodrigues@email.com',    '(11)97000-0001', 'pai'),
  ('a1b2c3d4-0000-0000-0001-000000000002'::UUID, :school_id, 'Helena Santos Rodrigues',   '234.567.890-12', 'helena.santos@email.com',     '(11)97000-0002', 'mãe'),
  ('a1b2c3d4-0000-0000-0001-000000000003'::UUID, :school_id, 'Paulo Costa Ferreira',      '345.678.901-23', 'paulo.costa@email.com',       '(11)97000-0003', 'pai'),
  ('a1b2c3d4-0000-0000-0001-000000000004'::UUID, :school_id, 'Cláudia Almeida Pereira',   '456.789.012-34', 'claudia.pereira@email.com',   '(11)97000-0004', 'mãe'),
  ('a1b2c3d4-0000-0000-0001-000000000005'::UUID, :school_id, 'Roberto Carvalho Nunes',    '567.890.123-45', 'roberto.carvalho@email.com',  '(11)97000-0005', 'responsável'),
  ('a1b2c3d4-0000-0000-0001-000000000006'::UUID, :school_id, 'Marcia Melo Souza',         '678.901.234-56', 'marcia.melo@email.com',       '(11)97000-0006', 'mãe'),
  ('a1b2c3d4-0000-0000-0001-000000000007'::UUID, :school_id, 'Antônio Rocha Martins',     '789.012.345-67', 'antonio.rocha@email.com',     '(11)97000-0007', 'pai'),
  ('a1b2c3d4-0000-0000-0001-000000000008'::UUID, :school_id, 'Sandra Oliveira Pedro',     '890.123.456-78', 'sandra.oliveira@email.com',   '(11)97000-0008', 'mãe'),
  ('a1b2c3d4-0000-0000-0001-000000000009'::UUID, :school_id, 'Luiz Henrique Gomes Lima',  '901.234.567-89', 'luiz.lima@email.com',         '(11)97000-0009', 'pai'),
  ('a1b2c3d4-0000-0000-0001-000000000010'::UUID, :school_id, 'Fátima Regina Alves',       '012.345.678-90', 'fatima.alves@email.com',      '(11)97000-0010', 'responsável')
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- MATRÍCULAS POR TURMA
-- ──────────────────────────────────────────────────────────────
INSERT INTO student_class_enrollments (student_id, class_id, enrolled_at, active)
SELECT s.id, :class_1a, '2025-02-03', true
FROM students s
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2025001','2025002','2025003','2025004')
ON CONFLICT (student_id, class_id) DO NOTHING;

INSERT INTO student_class_enrollments (student_id, class_id, enrolled_at, active)
SELECT s.id, :class_2b, '2025-02-03', true
FROM students s
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2024001','2024002','2024003')
ON CONFLICT (student_id, class_id) DO NOTHING;

INSERT INTO student_class_enrollments (student_id, class_id, enrolled_at, active)
SELECT s.id, :class_3c, '2025-02-03', true
FROM students s
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2023001','2023002','2023003')
ON CONFLICT (student_id, class_id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- FREQUÊNCIA — Jan, Fev e Mar 2025 (semanas de 2ª a 6ª)
-- Todas as turmas, disciplina principal da turma
-- ──────────────────────────────────────────────────────────────

-- 1A — Matemática (Jan–Mar)
INSERT INTO attendance_records (school_id, class_id, subject_id, student_id, date, status, recorded_by)
SELECT
  :school_id,
  :class_1a,
  :subj_mat,
  s.id,
  d.dt::DATE,
  (ARRAY['present','present','present','present','absent','late','excused'])[
    floor(random() * 7 + 1)::INT
  ]::attendance_status,
  :teacher_mat
FROM students s
CROSS JOIN (
  SELECT generate_series AS dt
  FROM generate_series('2025-01-06'::DATE, '2025-03-28'::DATE, '7 days')
) d
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2025001','2025002','2025003','2025004')
  AND s.active = true
ON CONFLICT (class_id, subject_id, student_id, date) DO NOTHING;

-- 2B — Língua Portuguesa (Jan–Mar)
INSERT INTO attendance_records (school_id, class_id, subject_id, student_id, date, status, recorded_by)
SELECT
  :school_id,
  :class_2b,
  :subj_port,
  s.id,
  d.dt::DATE,
  (ARRAY['present','present','present','absent','late'])[
    floor(random() * 5 + 1)::INT
  ]::attendance_status,
  :teacher_port
FROM students s
CROSS JOIN (
  SELECT generate_series AS dt
  FROM generate_series('2025-01-06'::DATE, '2025-03-28'::DATE, '7 days')
) d
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2024001','2024002','2024003')
  AND s.active = true
ON CONFLICT (class_id, subject_id, student_id, date) DO NOTHING;

-- 3C — História (Jan–Mar)
INSERT INTO attendance_records (school_id, class_id, subject_id, student_id, date, status, recorded_by)
SELECT
  :school_id,
  :class_3c,
  :subj_hist,
  s.id,
  d.dt::DATE,
  (ARRAY['present','present','present','present','absent'])[
    floor(random() * 5 + 1)::INT
  ]::attendance_status,
  :teacher_hist
FROM students s
CROSS JOIN (
  SELECT generate_series AS dt
  FROM generate_series('2025-01-06'::DATE, '2025-03-28'::DATE, '7 days')
) d
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2023001','2023002','2023003')
  AND s.active = true
ON CONFLICT (class_id, subject_id, student_id, date) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- NOTAS — 1º Bimestre
-- ──────────────────────────────────────────────────────────────

-- 1A Matemática
INSERT INTO grade_records (school_id, student_id, class_id, subject_id, academic_period_id, score, max_score, grade_type, description, recorded_by)
SELECT
  :school_id, s.id, :class_1a, :subj_mat, :period_bim1,
  ROUND((5.5 + random() * 4.5)::NUMERIC, 1),
  10.00, 'prova', 'Prova Bimestral — Números e Operações', :teacher_mat
FROM students s
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2025001','2025002','2025003','2025004')
  AND s.active = true
ON CONFLICT DO NOTHING;

-- 1A Português
INSERT INTO grade_records (school_id, student_id, class_id, subject_id, academic_period_id, score, max_score, grade_type, description, recorded_by)
SELECT
  :school_id, s.id, :class_1a, :subj_port, :period_bim1,
  ROUND((6.0 + random() * 4.0)::NUMERIC, 1),
  10.00, 'trabalho', 'Trabalho — Interpretação de Texto', :teacher_port
FROM students s
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2025001','2025002','2025003','2025004')
  AND s.active = true
ON CONFLICT DO NOTHING;

-- 2B Matemática
INSERT INTO grade_records (school_id, student_id, class_id, subject_id, academic_period_id, score, max_score, grade_type, description, recorded_by)
SELECT
  :school_id, s.id, :class_2b, :subj_mat, :period_bim1,
  ROUND((5.0 + random() * 5.0)::NUMERIC, 1),
  10.00, 'prova', 'Prova Bimestral — Frações e Porcentagens', :teacher_mat
FROM students s
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2024001','2024002','2024003')
  AND s.active = true
ON CONFLICT DO NOTHING;

-- 3C Ciências
INSERT INTO grade_records (school_id, student_id, class_id, subject_id, academic_period_id, score, max_score, grade_type, description, recorded_by)
SELECT
  :school_id, s.id, :class_3c, :subj_cien, :period_bim1,
  ROUND((6.5 + random() * 3.5)::NUMERIC, 1),
  10.00, 'prova', 'Prova — Sistema Solar e Astronomia', :teacher_cien
FROM students s
WHERE s.school_id = :school_id
  AND s.enrollment_code IN ('2023001','2023002','2023003')
  AND s.active = true
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- OCORRÊNCIAS DE EXEMPLO
-- ──────────────────────────────────────────────────────────────
INSERT INTO occurrences (school_id, student_id, class_id, reported_by, type, severity, description, resolved)
SELECT
  :school_id,
  s.id,
  :class_1a,
  :teacher_mat,
  'disciplinar',
  'low',
  'Aluno conversou durante a aula e foi advertido verbalmente.',
  false
FROM students s
WHERE s.school_id = :school_id AND s.enrollment_code = '2025002'
ON CONFLICT DO NOTHING;

INSERT INTO occurrences (school_id, student_id, class_id, reported_by, type, severity, description, resolved, resolved_at, resolved_by, resolution_notes)
SELECT
  :school_id,
  s.id,
  :class_2b,
  :teacher_port,
  'administrativo',
  'medium',
  'Aluno esqueceu material didático pela terceira vez consecutiva.',
  true,
  '2025-02-20 14:00:00',
  :admin_user,
  'Responsável foi comunicado e se comprometeu a resolver a situação.'
FROM students s
WHERE s.school_id = :school_id AND s.enrollment_code = '2024001'
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- COMUNICADOS DE EXEMPLO
-- ──────────────────────────────────────────────────────────────
INSERT INTO announcements (school_id, class_id, titulo, conteudo, fixado, created_by) VALUES
  (:school_id, NULL,
   'Início do Ano Letivo 2025',
   'Prezados responsáveis, informamos que as aulas terão início em 03/02/2025. Pedimos que os alunos compareçam uniformizados e com o material completo.',
   true, :admin_user),
  (:school_id, :class_1a,
   'Lista de Material — 1A (6º Ano)',
   'Segue abaixo a lista de materiais necessários para o 6º ano turma 1A: cadernos, lápis, borracha, régua, compasso e livros didáticos conforme lista afixada na secretaria.',
   false, :teacher_mat),
  (:school_id, :class_2b,
   'Recuperação Paralela — 2B',
   'Alunos com média inferior a 5.0 deverão comparecer às aulas de recuperação às terças-feiras das 17h às 18h30. Frequência obrigatória.',
   false, :teacher_port),
  (:school_id, NULL,
   'Reunião de Pais e Mestres — Abril 2025',
   'A Reunião de Pais e Mestres referente ao 1º Bimestre ocorrerá no dia 22/04/2025, às 19h, no auditório da escola. Presença indispensável.',
   true, :admin_user),
  (:school_id, :class_3c,
   'Semana de Ciências — 3C participa!',
   'A turma 3C foi selecionada para apresentar projetos na Feira de Ciências regional. Os projetos deverão ser entregues até 30/04/2025. Parabéns à turma!',
   false, :teacher_cien)
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- EVENTOS ESCOLARES
-- ──────────────────────────────────────────────────────────────
INSERT INTO events (school_id, title, description, event_type, start_date, end_date, all_day, created_by) VALUES
  (:school_id, 'Semana de Provas — 1º Bimestre',
   'Período de avaliações bimestrais para todas as turmas.',
   'exam', '2025-04-07 07:30:00', '2025-04-11 17:00:00', false, :admin_user),

  (:school_id, 'Conselho de Classe — 1º Bimestre',
   'Reunião de conselho de classe com todos os professores e coordenação.',
   'meeting', '2025-04-15 08:00:00', '2025-04-15 12:00:00', false, :admin_user),

  (:school_id, 'Reunião de Pais e Mestres',
   'RPM referente ao 1º Bimestre. Presença obrigatória dos responsáveis.',
   'meeting', '2025-04-22 19:00:00', '2025-04-22 21:00:00', false, :admin_user),

  (:school_id, 'Recesso de Tiradentes',
   'Feriado prolongado de Tiradentes — sem aulas.',
   'holiday', '2025-04-18 00:00:00', '2025-04-22 23:59:59', true, :admin_user),

  (:school_id, 'Festa Junina da Escola',
   'Grande festa junina com apresentações das turmas. Alunos, responsáveis e comunidade convidados. Traje típico opcional.',
   'activity', '2025-06-21 14:00:00', '2025-06-21 20:00:00', false, :admin_user),

  (:school_id, 'Feira de Ciências Regional',
   'Apresentação dos projetos de Ciências na Feira Regional. Abertura ao público às 14h.',
   'activity', '2025-05-16 09:00:00', '2025-05-16 17:00:00', false, :teacher_cien)
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- MENSAGENS ESCOLA ↔ RESPONSÁVEL (exemplos)
-- ──────────────────────────────────────────────────────────────
INSERT INTO messages (school_id, sender_id, recipient_id, subject, body, read)
VALUES
  (:school_id, :admin_user, :teacher_mat,
   'Reunião pedagógica',
   'Prof. Carlos, há reunião pedagógica na sexta-feira às 15h. Por favor confirme presença. Grata.',
   false),
  (:school_id, :teacher_port, :admin_user,
   'Solicitação de material',
   'Diretora, precisamos de mais cópias do livro de Português para a turma 2B. Poderia providenciar? Obrigada.',
   true),
  (:school_id, :secretary, :teacher_hist,
   'Documentação pendente',
   'Prof. Ricardo, sua documentação de atualização cadastral está pendente na secretaria. Favor comparecer até sexta.',
   false)
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- NOTIFICAÇÕES
-- ──────────────────────────────────────────────────────────────
INSERT INTO notifications (school_id, user_id, title, body, type, read) VALUES
  (:school_id, :teacher_mat,  'Novo aluno matriculado',    'Ana Paula Rodrigues foi matriculada na turma 1A.',                           'info',    false),
  (:school_id, :admin_user,   'Inadimplência detectada',   '2 responsáveis com mensalidades em atraso há mais de 30 dias.',              'warning', false),
  (:school_id, :secretary,    'RPM agendada',              'A Reunião de Pais e Mestres está confirmada para 22/04/2025.',               'info',    true),
  (:school_id, :teacher_port, 'Ocorrência registrada',     'Uma ocorrência foi registrada para aluno da turma 2B.',                     'info',    false),
  (:school_id, :admin_user,   'Feira de Ciências aprovada','A escola foi aceita na Feira de Ciências Regional de Maio/2025. Parabéns!', 'success', false)
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- MENSALIDADES — Jan a Jun 2025
-- ──────────────────────────────────────────────────────────────
INSERT INTO financial_records (school_id, student_id, description, amount, due_date, payment_status, paid_date, payment_method)
SELECT
  :school_id,
  s.id,
  'Mensalidade ' || to_char(m.month_date, 'FMMonth/YYYY'),
  780.00,
  (date_trunc('month', m.month_date) + interval '9 days')::DATE,
  CASE
    WHEN m.month_date < '2025-04-01' THEN 'paid'::payment_status
    WHEN m.month_date < '2025-05-01' AND random() > 0.25 THEN 'paid'::payment_status
    ELSE 'pending'::payment_status
  END,
  CASE
    WHEN m.month_date < '2025-04-01'
      THEN (date_trunc('month', m.month_date) + interval '8 days')::DATE
    WHEN m.month_date < '2025-05-01' AND random() > 0.25
      THEN (date_trunc('month', m.month_date) + interval '11 days')::DATE
    ELSE NULL
  END,
  CASE WHEN random() > 0.4 THEN 'pix' WHEN random() > 0.5 THEN 'cartao' ELSE 'boleto' END
FROM students s
CROSS JOIN (
  SELECT generate_series('2025-01-01'::DATE, '2025-06-01'::DATE, '1 month') AS month_date
) m
WHERE s.school_id = :school_id AND s.active = true
ON CONFLICT DO NOTHING;

COMMIT;
