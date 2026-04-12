-- ============================================================
-- Lexend Scholar — Boletim Escolar por Aluno e Período
-- Referência: database_schema.sql
-- Tabelas: grade_records, subjects, students, academic_periods
--
-- Pesos por tipo de avaliação:
--   prova        → 0.60
--   trabalho     → 0.30
--   participacao → 0.10
--
-- Situação:
--   aprovado     → média >= 6.0
--   recuperacao  → média >= 4.0 e < 6.0
--   reprovado    → média < 4.0
--
-- Parâmetros:
--   :student_id         UUID do aluno
--   :academic_period_id UUID do período letivo
-- ============================================================

WITH weighted_grades AS (
  SELECT
    gr.student_id,
    gr.subject_id,
    gr.academic_period_id,
    gr.grade_type,
    gr.score,
    gr.max_score,
    -- Normalizar nota para escala 0-10
    ROUND(
      CASE WHEN gr.max_score > 0
      THEN (gr.score / gr.max_score) * 10
      ELSE 0 END,
      2
    )                                               AS score_normalized,
    -- Peso conforme tipo de avaliação
    CASE gr.grade_type
      WHEN 'prova'        THEN 0.60
      WHEN 'trabalho'     THEN 0.30
      WHEN 'participacao' THEN 0.10
      ELSE                     0.00
    END                                             AS weight
  FROM grade_records gr
  WHERE gr.student_id         = :student_id
    AND gr.academic_period_id = :academic_period_id
    AND gr.score IS NOT NULL
),
subject_averages AS (
  SELECT
    wg.student_id,
    wg.subject_id,
    wg.academic_period_id,
    -- Média ponderada normalizada
    ROUND(
      SUM(
        CASE WHEN wg.weight > 0
        THEN wg.score_normalized * wg.weight
        ELSE 0 END
      ) / NULLIF(SUM(CASE WHEN wg.weight > 0 THEN wg.weight ELSE 0 END), 0),
      2
    )                                               AS media_ponderada,
    -- Médias por tipo de avaliação
    ROUND(AVG(CASE WHEN wg.grade_type = 'prova'        THEN wg.score_normalized END), 2) AS media_provas,
    ROUND(AVG(CASE WHEN wg.grade_type = 'trabalho'     THEN wg.score_normalized END), 2) AS media_trabalhos,
    ROUND(AVG(CASE WHEN wg.grade_type = 'participacao' THEN wg.score_normalized END), 2) AS media_participacao,
    COUNT(wg.grade_type)                            AS total_avaliacoes
  FROM weighted_grades wg
  GROUP BY wg.student_id, wg.subject_id, wg.academic_period_id
)
SELECT
  s.id                                              AS student_id,
  s.full_name                                       AS aluno,
  s.enrollment_code                                 AS matricula,
  ap.name                                           AS periodo,
  subj.id                                           AS subject_id,
  subj.name                                         AS disciplina,
  subj.code                                         AS codigo_disciplina,
  sa.media_provas,
  sa.media_trabalhos,
  sa.media_participacao,
  sa.media_ponderada,
  sa.total_avaliacoes,
  -- Situação baseada na média ponderada
  CASE
    WHEN sa.media_ponderada >= 6.0 THEN 'aprovado'
    WHEN sa.media_ponderada >= 4.0 THEN 'recuperacao'
    ELSE                                'reprovado'
  END                                               AS situacao
FROM subject_averages sa
INNER JOIN students s
        ON s.id = sa.student_id
INNER JOIN subjects subj
        ON subj.id = sa.subject_id
INNER JOIN academic_periods ap
        ON ap.id = sa.academic_period_id
ORDER BY subj.name ASC;
