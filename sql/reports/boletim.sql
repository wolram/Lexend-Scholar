-- ============================================================
-- Lexend Scholar — Boletim Escolar por Aluno
-- Referência: database_schema.sql
--   Tabelas: grade_records, students, subjects, academic_periods,
--            classes, attendance_records, student_class_enrollments
--
-- Parâmetros:
--   :school_id          UUID da escola
--   :student_id         UUID do aluno
--   :academic_year_id   UUID do ano letivo
-- ============================================================

-- ============================================================
-- 1. DADOS DO ALUNO (cabeçalho do boletim)
-- ============================================================
SELECT
  s.enrollment_code,
  s.full_name,
  s.birth_date,
  g.name                                AS grade_name,
  c.name                                AS class_name,
  ay.name                               AS academic_year,
  sch.name                              AS school_name
FROM students s
INNER JOIN student_class_enrollments sce ON sce.student_id = s.id AND sce.active = TRUE
INNER JOIN classes c                     ON c.id = sce.class_id
INNER JOIN grades g                      ON g.id = c.grade_id
INNER JOIN academic_years ay             ON ay.id = c.academic_year_id
INNER JOIN schools sch                   ON sch.id = s.school_id
WHERE s.id        = :student_id
  AND s.school_id = :school_id
  AND ay.id       = :academic_year_id
LIMIT 1;

-- ============================================================
-- 2. NOTAS POR DISCIPLINA E BIMESTRE (pivot)
-- ============================================================
WITH notas AS (
  SELECT
    sub.name                                                        AS disciplina,
    sub.id                                                          AS subject_id,
    ap.name                                                         AS periodo,
    ap.id                                                           AS period_id,
    ROUND(AVG(gr.score), 2)                                         AS media_periodo,
    gr.max_score                                                    AS nota_maxima
  FROM grade_records gr
  INNER JOIN subjects sub         ON sub.id = gr.subject_id
  INNER JOIN academic_periods ap  ON ap.id  = gr.academic_period_id
  WHERE gr.school_id  = :school_id
    AND gr.student_id = :student_id
    AND ap.academic_year_id = :academic_year_id
  GROUP BY sub.id, sub.name, ap.id, ap.name, gr.max_score
),
media_anual AS (
  SELECT
    subject_id,
    disciplina,
    ROUND(AVG(media_periodo), 2)  AS media_anual,
    MIN(nota_maxima)              AS nota_maxima,
    CASE WHEN AVG(media_periodo) >= 6 THEN 'Aprovado'
         WHEN AVG(media_periodo) >= 4 THEN 'Recuperação'
         ELSE 'Reprovado'
    END                           AS situacao
  FROM notas
  GROUP BY subject_id, disciplina
)
SELECT
  n.disciplina,
  n.periodo,
  n.media_periodo,
  n.nota_maxima,
  ma.media_anual,
  ma.situacao
FROM notas n
INNER JOIN media_anual ma ON ma.subject_id = n.subject_id
ORDER BY n.disciplina, n.periodo;

-- ============================================================
-- 3. FREQUÊNCIA POR DISCIPLINA
-- ============================================================
WITH aulas AS (
  SELECT
    sub.name                                         AS disciplina,
    sub.id                                           AS subject_id,
    COUNT(ar.id)                                     AS total_aulas,
    COUNT(CASE WHEN ar.status = 'present' OR ar.status = 'late' THEN 1 END) AS presencas,
    COUNT(CASE WHEN ar.status = 'absent'  THEN 1 END) AS faltas,
    COUNT(CASE WHEN ar.status = 'excused' THEN 1 END) AS faltas_justificadas
  FROM attendance_records ar
  INNER JOIN subjects sub ON sub.id = ar.subject_id
  INNER JOIN classes c    ON c.id   = ar.class_id
  WHERE ar.school_id  = :school_id
    AND ar.student_id = :student_id
    AND c.academic_year_id = :academic_year_id
  GROUP BY sub.id, sub.name
)
SELECT
  disciplina,
  total_aulas,
  presencas,
  faltas,
  faltas_justificadas,
  ROUND(presencas::NUMERIC / NULLIF(total_aulas, 0) * 100, 1) AS frequencia_pct,
  -- Limite legal: 75% de frequência mínima
  CASE WHEN (presencas::NUMERIC / NULLIF(total_aulas, 0)) >= 0.75
    THEN 'Regular' ELSE 'Atenção — Baixa frequência'
  END AS status_frequencia
FROM aulas
ORDER BY disciplina;

-- ============================================================
-- 4. RESUMO GERAL DO ALUNO (para rodapé do boletim)
-- ============================================================
SELECT
  COUNT(DISTINCT gr.subject_id)                                   AS total_disciplinas,
  ROUND(AVG(gr.score / NULLIF(gr.max_score, 0) * 10), 2)         AS media_geral_ponderada,
  COUNT(CASE WHEN gr.score / NULLIF(gr.max_score, 0) * 10 >= 6   THEN 1 END) AS disciplinas_aprovadas,
  COUNT(CASE WHEN gr.score / NULLIF(gr.max_score, 0) * 10 BETWEEN 4 AND 5.9 THEN 1 END) AS disciplinas_recuperacao,
  COUNT(CASE WHEN gr.score / NULLIF(gr.max_score, 0) * 10 < 4    THEN 1 END) AS disciplinas_reprovadas,
  -- Frequência geral
  COUNT(ar.id)                                                    AS total_aulas_gerais,
  COUNT(CASE WHEN ar.status IN ('present','late')                 THEN 1 END) AS total_presencas,
  ROUND(
    COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END)::NUMERIC
    / NULLIF(COUNT(ar.id), 0) * 100, 1
  )                                                               AS frequencia_geral_pct
FROM grade_records gr
INNER JOIN academic_periods ap ON ap.id = gr.academic_period_id
LEFT JOIN attendance_records ar
       ON ar.student_id = gr.student_id
      AND ar.school_id  = gr.school_id
INNER JOIN classes c ON c.id = ar.class_id
WHERE gr.school_id  = :school_id
  AND gr.student_id = :student_id
  AND ap.academic_year_id = :academic_year_id
  AND c.academic_year_id  = :academic_year_id;
