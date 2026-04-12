-- ============================================================
-- Lexend Scholar — Relatório de Inadimplência Financeira
-- Referência: database_schema.sql
-- Tabelas: financial_records, students, student_class_enrollments, classes
--
-- Parâmetros:
--   :school_id   UUID da escola
--   :min_days    Dias mínimos de atraso (DEFAULT 1)
-- ============================================================

SELECT
  s.id                                                    AS student_id,
  s.enrollment_code                                       AS matricula,
  s.full_name                                             AS aluno,
  s.email                                                 AS email_aluno,
  c.name                                                  AS turma,
  fr.id                                                   AS financial_record_id,
  fr.description                                          AS descricao_cobranca,
  fr.amount                                               AS valor,
  fr.due_date                                             AS vencimento,
  fr.payment_status                                       AS status,
  (CURRENT_DATE - fr.due_date)                            AS dias_atraso,
  CASE
    WHEN (CURRENT_DATE - fr.due_date) <= 30  THEN 'Baixo'
    WHEN (CURRENT_DATE - fr.due_date) <= 60  THEN 'Médio'
    WHEN (CURRENT_DATE - fr.due_date) <= 90  THEN 'Alto'
    ELSE                                          'Crítico'
  END                                                     AS risco,
  -- Total em aberto para o aluno (window function)
  SUM(fr.amount) OVER (PARTITION BY fr.student_id)        AS total_divida_aluno,
  COUNT(fr.id)   OVER (PARTITION BY fr.student_id)        AS parcelas_em_atraso
FROM financial_records fr
INNER JOIN students s
        ON s.id        = fr.student_id
       AND s.school_id = fr.school_id
       AND s.active    = TRUE
-- Turma atual do aluno (matrícula ativa)
LEFT JOIN student_class_enrollments sce
       ON sce.student_id = s.id
      AND sce.active     = TRUE
LEFT JOIN classes c
       ON c.id = sce.class_id
WHERE fr.school_id      = :school_id
  AND fr.payment_status = 'pending'
  AND fr.due_date       < CURRENT_DATE
  AND (CURRENT_DATE - fr.due_date) >= :min_days
ORDER BY
  dias_atraso DESC,
  c.name      ASC,
  s.full_name ASC;
