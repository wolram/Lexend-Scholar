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
\set grade_1em      '\'a1b2c3d4-0000-0000-0000-000000000030\''
\set grade_2em      '\'a1b2c3d4-0000-0000-0000-000000000031\''
\set grade_3em      '\'a1b2c3d4-0000-0000-0000-000000000032\''
\set class_1a       '\'a1b2c3d4-0000-0000-0000-000000000040\''
\set class_1b       '\'a1b2c3d4-0000-0000-0000-000000000041\''
\set class_2a       '\'a1b2c3d4-0000-0000-0000-000000000042\''
\set class_3a       '\'a1b2c3d4-0000-0000-0000-000000000043\''
\set admin_user     '\'a1b2c3d4-0000-0000-0000-000000000050\''
\set teacher_math   '\'a1b2c3d4-0000-0000-0000-000000000051\''
\set teacher_port   '\'a1b2c3d4-0000-0000-0000-000000000052\''
\set teacher_hist   '\'a1b2c3d4-0000-0000-0000-000000000053\''
\set teacher_bio    '\'a1b2c3d4-0000-0000-0000-000000000054\''
\set secretary      '\'a1b2c3d4-0000-0000-0000-000000000055\''
\set subj_mat       '\'a1b2c3d4-0000-0000-0000-000000000060\''
\set subj_port      '\'a1b2c3d4-0000-0000-0000-000000000061\''
\set subj_hist      '\'a1b2c3d4-0000-0000-0000-000000000062\''
\set subj_geo       '\'a1b2c3d4-0000-0000-0000-000000000063\''
\set subj_bio       '\'a1b2c3d4-0000-0000-0000-000000000064\''
\set subj_quim      '\'a1b2c3d4-0000-0000-0000-000000000065\''
\set subj_fis       '\'a1b2c3d4-0000-0000-0000-000000000066\''
\set subj_ing       '\'a1b2c3d4-0000-0000-0000-000000000067\''
\set subj_ef        '\'a1b2c3d4-0000-0000-0000-000000000068\''

BEGIN;

-- ──────────────────────────────────────────────────────────────
-- SCHOOL
-- ──────────────────────────────────────────────────────────────
INSERT INTO schools (id, name, cnpj, email, phone, address, city, state, zip_code, plan, max_students, subscription_status)
VALUES (
  :school_id,
  'Escola Estadual Presidente Vargas',
  '12.345.678/0001-99',
  'contato@epvargas.edu.br',
  '(11) 3456-7890',
  'Rua das Flores, 150',
  'São Paulo', 'SP', '01310-100',
  'pro', 500, 'active'
)
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- USERS (staff)
-- ──────────────────────────────────────────────────────────────
INSERT INTO users (id, school_id, email, full_name, role, active) VALUES
  (:admin_user,   :school_id, 'diretora@epvargas.edu.br',      'Dra. Maria Aparecida Souza',  'admin',     true),
  (:teacher_math, :school_id, 'prof.matematica@epvargas.edu.br','Prof. Carlos Eduardo Lima',   'teacher',   true),
  (:teacher_port, :school_id, 'prof.portugues@epvargas.edu.br', 'Profa. Ana Beatriz Ferreira', 'teacher',   true),
  (:teacher_hist, :school_id, 'prof.historia@epvargas.edu.br',  'Prof. Ricardo Mendes',        'teacher',   true),
  (:teacher_bio,  :school_id, 'prof.biologia@epvargas.edu.br',  'Profa. Juliana Costa',        'teacher',   true),
  (:secretary,    :school_id, 'secretaria@epvargas.edu.br',     'Sra. Fernanda Oliveira',      'secretary', true)
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- ACADEMIC YEAR
-- ──────────────────────────────────────────────────────────────
INSERT INTO academic_years (id, school_id, name, start_date, end_date, active)
VALUES (:year_2025, :school_id, '2025', '2025-02-10', '2025-12-05', true)
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- ACADEMIC PERIODS (bimestres)
-- ──────────────────────────────────────────────────────────────
INSERT INTO academic_periods (id, school_id, academic_year_id, name, start_date, end_date) VALUES
  (:period_bim1, :school_id, :year_2025, '1º Bimestre', '2025-02-10', '2025-04-11'),
  (:period_bim2, :school_id, :year_2025, '2º Bimestre', '2025-04-14', '2025-06-27'),
  (:period_bim3, :school_id, :year_2025, '3º Bimestre', '2025-07-28', '2025-09-26'),
  (:period_bim4, :school_id, :year_2025, '4º Bimestre', '2025-09-29', '2025-12-05')
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- GRADES (series)
-- ──────────────────────────────────────────────────────────────
INSERT INTO grades (id, school_id, name, level) VALUES
  (:grade_1em, :school_id, '1º Ano EM', 'medio'),
  (:grade_2em, :school_id, '2º Ano EM', 'medio'),
  (:grade_3em, :school_id, '3º Ano EM', 'medio')
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- CLASSES
-- ──────────────────────────────────────────────────────────────
INSERT INTO classes (id, school_id, grade_id, academic_year_id, name, teacher_id, max_students) VALUES
  (:class_1a, :school_id, :grade_1em, :year_2025, '1A', :teacher_math, 35),
  (:class_1b, :school_id, :grade_1em, :year_2025, '1B', :teacher_port, 34),
  (:class_2a, :school_id, :grade_2em, :year_2025, '2A', :teacher_hist, 33),
  (:class_3a, :school_id, :grade_3em, :year_2025, '3A', :teacher_bio,  30)
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- SUBJECTS
-- ──────────────────────────────────────────────────────────────
INSERT INTO subjects (id, school_id, name, code) VALUES
  (:subj_mat,  :school_id, 'Matemática',          'MAT'),
  (:subj_port, :school_id, 'Língua Portuguesa',   'PORT'),
  (:subj_hist, :school_id, 'História',             'HIST'),
  (:subj_geo,  :school_id, 'Geografia',            'GEO'),
  (:subj_bio,  :school_id, 'Biologia',             'BIO'),
  (:subj_quim, :school_id, 'Química',              'QUIM'),
  (:subj_fis,  :school_id, 'Física',               'FIS'),
  (:subj_ing,  :school_id, 'Língua Inglesa',       'ING'),
  (:subj_ef,   :school_id, 'Educação Física',      'EF')
ON CONFLICT (id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- CLASS SUBJECTS
-- ──────────────────────────────────────────────────────────────
INSERT INTO class_subjects (class_id, subject_id, teacher_id, weekly_hours) VALUES
  (:class_1a, :subj_mat,  :teacher_math, 5),
  (:class_1a, :subj_port, :teacher_port, 5),
  (:class_1a, :subj_hist, :teacher_hist, 3),
  (:class_1a, :subj_bio,  :teacher_bio,  3),
  (:class_1b, :subj_mat,  :teacher_math, 5),
  (:class_1b, :subj_port, :teacher_port, 5),
  (:class_2a, :subj_mat,  :teacher_math, 5),
  (:class_2a, :subj_port, :teacher_port, 4),
  (:class_2a, :subj_bio,  :teacher_bio,  3),
  (:class_3a, :subj_mat,  :teacher_math, 5),
  (:class_3a, :subj_bio,  :teacher_bio,  4)
ON CONFLICT (class_id, subject_id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- STUDENTS (30 for class 1A, 10 for others — realistic names)
-- ──────────────────────────────────────────────────────────────
INSERT INTO students (school_id, enrollment_code, full_name, birth_date, gender, email, phone, city, state, active) VALUES
  -- 1A
  (:school_id, '2025001', 'Ana Paula Rodrigues',      '2009-03-12', 'F', 'ana.rodrigues@aluno.epvargas.edu.br',      '(11)98000-0001', 'São Paulo', 'SP', true),
  (:school_id, '2025002', 'Bruno Henrique Santos',    '2009-07-24', 'M', 'bruno.santos@aluno.epvargas.edu.br',       '(11)98000-0002', 'São Paulo', 'SP', true),
  (:school_id, '2025003', 'Carla Mendonça Lima',      '2009-01-05', 'F', 'carla.lima@aluno.epvargas.edu.br',         '(11)98000-0003', 'São Paulo', 'SP', true),
  (:school_id, '2025004', 'Daniel Ferreira Costa',   '2009-11-30', 'M', 'daniel.costa@aluno.epvargas.edu.br',       '(11)98000-0004', 'São Paulo', 'SP', true),
  (:school_id, '2025005', 'Eduarda Alves Pereira',   '2009-06-18', 'F', 'eduarda.pereira@aluno.epvargas.edu.br',    '(11)98000-0005', 'São Paulo', 'SP', true),
  (:school_id, '2025006', 'Felipe Gomes Almeida',    '2009-09-02', 'M', 'felipe.almeida@aluno.epvargas.edu.br',     '(11)98000-0006', 'São Paulo', 'SP', true),
  (:school_id, '2025007', 'Gabriela Nunes Carvalho', '2009-04-20', 'F', 'gabriela.carvalho@aluno.epvargas.edu.br',  '(11)98000-0007', 'Guarulhos', 'SP', true),
  (:school_id, '2025008', 'Henrique Souza Melo',     '2009-12-15', 'M', 'henrique.melo@aluno.epvargas.edu.br',      '(11)98000-0008', 'Guarulhos', 'SP', true),
  (:school_id, '2025009', 'Isabela Martins Rocha',   '2009-02-28', 'F', 'isabela.rocha@aluno.epvargas.edu.br',      '(11)98000-0009', 'São Paulo', 'SP', true),
  (:school_id, '2025010', 'João Pedro Oliveira',     '2009-08-09', 'M', 'joao.oliveira@aluno.epvargas.edu.br',      '(11)98000-0010', 'São Paulo', 'SP', true),
  (:school_id, '2025011', 'Karina Lopes Dias',       '2009-05-14', 'F', 'karina.dias@aluno.epvargas.edu.br',        '(11)98000-0011', 'São Paulo', 'SP', true),
  (:school_id, '2025012', 'Lucas Vieira Barbosa',    '2009-10-21', 'M', 'lucas.barbosa@aluno.epvargas.edu.br',      '(11)98000-0012', 'São Paulo', 'SP', true),
  (:school_id, '2025013', 'Mariana Castro Freitas',  '2008-12-03', 'F', 'mariana.freitas@aluno.epvargas.edu.br',    '(11)98000-0013', 'Osasco',    'SP', true),
  (:school_id, '2025014', 'Nicolas Batista Ribeiro', '2009-03-27', 'M', 'nicolas.ribeiro@aluno.epvargas.edu.br',    '(11)98000-0014', 'São Paulo', 'SP', true),
  (:school_id, '2025015', 'Patrícia Araújo Teixeira','2009-07-11', 'F', 'patricia.teixeira@aluno.epvargas.edu.br',  '(11)98000-0015', 'São Paulo', 'SP', true),
  -- 1B
  (:school_id, '2025101', 'Rafael Cunha Monteiro',   '2009-01-22', 'M', 'rafael.monteiro@aluno.epvargas.edu.br',    '(11)98000-0101', 'São Paulo', 'SP', true),
  (:school_id, '2025102', 'Sofia Cardoso Nascimento','2009-08-17', 'F', 'sofia.nascimento@aluno.epvargas.edu.br',   '(11)98000-0102', 'São Paulo', 'SP', true),
  (:school_id, '2025103', 'Thiago Ramos Bezerra',    '2009-04-05', 'M', 'thiago.bezerra@aluno.epvargas.edu.br',     '(11)98000-0103', 'São Paulo', 'SP', true),
  -- 2A
  (:school_id, '2024001', 'Amanda Fontes Xavier',    '2008-02-14', 'F', 'amanda.xavier@aluno.epvargas.edu.br',      '(11)98000-0201', 'São Paulo', 'SP', true),
  (:school_id, '2024002', 'Caio Pinto Azevedo',      '2008-06-30', 'M', 'caio.azevedo@aluno.epvargas.edu.br',       '(11)98000-0202', 'São Paulo', 'SP', true),
  (:school_id, '2024003', 'Débora Leite Coelho',     '2008-09-19', 'F', 'debora.coelho@aluno.epvargas.edu.br',      '(11)98000-0203', 'Mauá',      'SP', true),
  -- 3A
  (:school_id, '2023001', 'Eduardo Pinheiro Brum',   '2007-03-08', 'M', 'eduardo.brum@aluno.epvargas.edu.br',       '(11)98000-0301', 'São Paulo', 'SP', true),
  (:school_id, '2023002', 'Fernanda Queiroz Salave', '2007-11-25', 'F', 'fernanda.salave@aluno.epvargas.edu.br',    '(11)98000-0302', 'São Paulo', 'SP', true),
  (:school_id, '2023003', 'Gustavo Abreu Torres',    '2007-07-04', 'M', 'gustavo.torres@aluno.epvargas.edu.br',     '(11)98000-0303', 'São Paulo', 'SP', true),
  -- Inactive student example
  (:school_id, '2024099', 'Henrique Duarte (Transferido)', '2008-05-20', 'M', NULL, NULL, 'São Paulo', 'SP', false)
ON CONFLICT (school_id, enrollment_code) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- GUARDIANS
-- ──────────────────────────────────────────────────────────────
INSERT INTO guardians (id, school_id, full_name, cpf, email, phone, relation) VALUES
  (gen_random_uuid(), :school_id, 'José Rodrigues',      '123.456.789-01', 'jose.rodrigues@email.com',    '(11)97000-0001', 'pai'),
  (gen_random_uuid(), :school_id, 'Helena Santos',       '234.567.890-12', 'helena.santos@email.com',     '(11)97000-0002', 'mãe'),
  (gen_random_uuid(), :school_id, 'Paulo Costa',         '345.678.901-23', 'paulo.costa@email.com',       '(11)97000-0003', 'pai'),
  (gen_random_uuid(), :school_id, 'Cláudia Ferreira',    '456.789.012-34', 'claudia.ferreira@email.com',  '(11)97000-0004', 'mãe'),
  (gen_random_uuid(), :school_id, 'Roberto Pereira',     '567.890.123-45', 'roberto.pereira@email.com',   '(11)97000-0005', 'responsável')
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- ENROLLMENTS
-- ──────────────────────────────────────────────────────────────
INSERT INTO student_class_enrollments (student_id, class_id, enrolled_at, active)
SELECT s.id, :class_1a, '2025-02-10', true
FROM students s
WHERE s.school_id = :school_id AND s.enrollment_code LIKE '2025%'
  AND s.enrollment_code < '2025100'
ON CONFLICT (student_id, class_id) DO NOTHING;

INSERT INTO student_class_enrollments (student_id, class_id, enrolled_at, active)
SELECT s.id, :class_1b, '2025-02-10', true
FROM students s
WHERE s.school_id = :school_id AND s.enrollment_code IN ('2025101','2025102','2025103')
ON CONFLICT (student_id, class_id) DO NOTHING;

INSERT INTO student_class_enrollments (student_id, class_id, enrolled_at, active)
SELECT s.id, :class_2a, '2025-02-10', true
FROM students s
WHERE s.school_id = :school_id AND s.enrollment_code IN ('2024001','2024002','2024003')
ON CONFLICT (student_id, class_id) DO NOTHING;

INSERT INTO student_class_enrollments (student_id, class_id, enrolled_at, active)
SELECT s.id, :class_3a, '2025-02-10', true
FROM students s
WHERE s.school_id = :school_id AND s.enrollment_code IN ('2023001','2023002','2023003')
ON CONFLICT (student_id, class_id) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- ATTENDANCE RECORDS (sample for March 2025, class 1A, math)
-- ──────────────────────────────────────────────────────────────
INSERT INTO attendance_records (school_id, class_id, subject_id, student_id, date, status, recorded_by)
SELECT
  :school_id,
  :class_1a,
  :subj_mat,
  s.id,
  d.dt::DATE,
  CASE
    WHEN random() < 0.85 THEN 'present'
    WHEN random() < 0.50 THEN 'absent'
    WHEN random() < 0.70 THEN 'late'
    ELSE 'excused'
  END::attendance_status,
  :teacher_math
FROM students s
CROSS JOIN (
  SELECT generate_series('2025-03-03'::DATE, '2025-03-28'::DATE, '7 days') AS dt
) d
WHERE s.school_id = :school_id
  AND s.enrollment_code LIKE '2025%'
  AND s.enrollment_code < '2025100'
  AND s.active = true
ON CONFLICT (class_id, subject_id, student_id, date) DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- GRADE RECORDS (1º Bimestre — class 1A — math and portuguese)
-- ──────────────────────────────────────────────────────────────
INSERT INTO grade_records (school_id, student_id, class_id, subject_id, academic_period_id, score, max_score, grade_type, description, recorded_by)
SELECT
  :school_id,
  s.id,
  :class_1a,
  :subj_mat,
  :period_bim1,
  ROUND((5 + random() * 5)::NUMERIC, 2),  -- score between 5.00 and 10.00
  10.00,
  'prova',
  'Prova 1 - Álgebra Básica',
  :teacher_math
FROM students s
WHERE s.school_id = :school_id
  AND s.enrollment_code LIKE '2025%'
  AND s.enrollment_code < '2025100'
  AND s.active = true
ON CONFLICT DO NOTHING;

INSERT INTO grade_records (school_id, student_id, class_id, subject_id, academic_period_id, score, max_score, grade_type, description, recorded_by)
SELECT
  :school_id,
  s.id,
  :class_1a,
  :subj_port,
  :period_bim1,
  ROUND((6 + random() * 4)::NUMERIC, 2),
  10.00,
  'trabalho',
  'Trabalho - Análise Literária Drummond',
  :teacher_port
FROM students s
WHERE s.school_id = :school_id
  AND s.enrollment_code LIKE '2025%'
  AND s.enrollment_code < '2025100'
  AND s.active = true
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- FINANCIAL RECORDS (mensalidades Março–Junho 2025)
-- ──────────────────────────────────────────────────────────────
INSERT INTO financial_records (school_id, student_id, description, amount, due_date, payment_status, paid_date, payment_method)
SELECT
  :school_id,
  s.id,
  'Mensalidade ' || to_char(m.month_date, 'FMMonth/YYYY'),
  850.00,
  (date_trunc('month', m.month_date) + interval '9 days')::DATE,
  CASE
    WHEN m.month_date < '2025-04-01' THEN 'paid'::payment_status
    WHEN m.month_date < '2025-05-01' AND random() > 0.3 THEN 'paid'::payment_status
    ELSE 'pending'::payment_status
  END,
  CASE
    WHEN m.month_date < '2025-04-01'
      THEN (date_trunc('month', m.month_date) + interval '8 days')::DATE
    WHEN m.month_date < '2025-05-01' AND random() > 0.3
      THEN (date_trunc('month', m.month_date) + interval '10 days')::DATE
    ELSE NULL
  END,
  CASE WHEN random() > 0.5 THEN 'pix' ELSE 'boleto' END
FROM students s
CROSS JOIN (
  SELECT generate_series('2025-03-01'::DATE, '2025-06-01'::DATE, '1 month') AS month_date
) m
WHERE s.school_id = :school_id AND s.active = true
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- EVENTS
-- ──────────────────────────────────────────────────────────────
INSERT INTO events (school_id, title, description, event_type, start_date, end_date, all_day, created_by) VALUES
  (:school_id, 'Conselho de Classe — 1º Bimestre', 'Reunião de conselho de classe para todos os professores', 'meeting',  '2025-04-15 08:00:00', '2025-04-15 12:00:00', false, :admin_user),
  (:school_id, 'Reunião de Pais e Mestres',        'RPM referente ao 1º bimestre',                             'meeting',  '2025-04-22 19:00:00', '2025-04-22 21:00:00', false, :admin_user),
  (:school_id, 'Semana de Provas — 1º Bimestre',   'Período de avaliações do 1º bimestre',                     'exam',     '2025-04-07 00:00:00', '2025-04-11 23:59:59', true,  :admin_user),
  (:school_id, 'Recesso Escolar',                  'Recesso Tiradentes',                                        'holiday',  '2025-04-18 00:00:00', '2025-04-22 23:59:59', true,  :admin_user),
  (:school_id, 'Festa Junina',                     'Festa junina da escola — alunos e responsáveis convidados', 'activity', '2025-06-21 14:00:00', '2025-06-21 20:00:00', false, :admin_user)
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- ASSIGNMENTS
-- ──────────────────────────────────────────────────────────────
INSERT INTO assignments (school_id, class_id, subject_id, teacher_id, title, description, due_date, max_score) VALUES
  (:school_id, :class_1a, :subj_mat,  :teacher_math, 'Lista de Exercícios — Funções',    'Resolva os exercícios 1 a 20 do livro didático, capítulo 3.', '2025-04-04', 10.00),
  (:school_id, :class_1a, :subj_port, :teacher_port, 'Redação — Carta Argumentativa',    'Escreva uma carta argumentativa sobre preservação ambiental.', '2025-04-08', 10.00),
  (:school_id, :class_2a, :subj_mat,  :teacher_math, 'Projeto — Geometria Analítica',    'Apresente um projeto sobre aplicações práticas de GA.', '2025-04-10', 10.00),
  (:school_id, :class_3a, :subj_bio,  :teacher_bio,  'Seminário — Genética e Sociedade', 'Apresente em grupo sobre engenharia genética e ética.', '2025-04-17', 10.00)
ON CONFLICT DO NOTHING;

-- ──────────────────────────────────────────────────────────────
-- NOTIFICATIONS (sample)
-- ──────────────────────────────────────────────────────────────
INSERT INTO notifications (school_id, user_id, title, body, type, read) VALUES
  (:school_id, :teacher_math, 'Novo aluno matriculado', 'Um novo aluno foi matriculado na turma 1A.', 'info',    false),
  (:school_id, :admin_user,   'Inadimplência detectada', '3 alunos com mensalidades em atraso há mais de 30 dias.', 'warning', false),
  (:school_id, :secretary,    'RPM agendada', 'A Reunião de Pais e Mestres está agendada para 22/04/2025.', 'info', true)
ON CONFLICT DO NOTHING;

COMMIT;
