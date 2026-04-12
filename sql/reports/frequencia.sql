-- ============================================================
-- Lexend Scholar — Relatório de Frequência Agregada
-- Referência: database_schema.sql
-- Tabela principal: attendance_records(id, student_id, class_id, date, status)
-- Status: present | absent | late | excused
--
-- Parâmetros:
--   :student_id  UUID do aluno   (opcional — NULL = todos)
--   :class_id    UUID da turma   (opcional — NULL = todas)
--   :date_from   Data inicial    (obrigatório)
--   :date_to     Data final      (obrigatório)
--   :school_id   UUID da escola  (obrigatório)
-- ============================================================

SELECT
  s.id                                                        AS student_id,
  s.enrollment_code                                           AS matricula,
  s.full_name                                                 AS aluno,
  c.id                                                        AS class_id,
  c.name                                                      AS turma,
  -- Totais de aulas no período
  COUNT(ar.id)                                                AS total_aulas,
  -- Presenças: present + late ambos contam como presença
  COUNT(CASE WHEN ar.status IN ('present', 'late')  THEN 1 END) AS presencas,
  -- Faltas não justificadas
  COUNT(CASE WHEN ar.status = 'absent'              THEN 1 END) AS faltas,
  -- Faltas justificadas
  COUNT(CASE WHEN ar.status = 'excused'             THEN 1 END) AS faltas_justificadas,
  -- Atrasos registrados
  COUNT(CASE WHEN ar.status = 'late'                THEN 1 END) AS atrasos,
  -- Percentual de frequência (presenças / total_aulas × 100)
  ROUND(
    COUNT(CASE WHEN ar.status IN ('present', 'late') THEN 1 END)::NUMERIC
    / NULLIF(COUNT(ar.id), 0) * 100,
    1
  )                                                           AS percentual,
  -- Situação conforme limite legal de 75%
  CASE
    WHEN COUNT(ar.id) = 0 THEN 'sem_registro'
    WHEN COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END)::NUMERIC
         / NULLIF(COUNT(ar.id), 0) >= 0.75 THEN 'regular'
    WHEN COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END)::NUMERIC
         / NULLIF(COUNT(ar.id), 0) >= 0.60 THEN 'atencao'
    ELSE 'critico'
  END                                                         AS situacao
FROM attendance_records ar
INNER JOIN students s
        ON s.id        = ar.student_id
       AND s.school_id = ar.school_id
       AND s.active    = TRUE
INNER JOIN classes c
        ON c.id = ar.class_id
WHERE ar.school_id = :school_id
  AND ar.date BETWEEN :date_from AND :date_to
  AND (:student_id IS NULL OR ar.student_id = :student_id::UUID)
  AND (:class_id   IS NULL OR ar.class_id   = :class_id::UUID)
GROUP BY
  s.id,
  s.enrollment_code,
  s.full_name,
  c.id,
  c.name
ORDER BY
  percentual ASC,
  c.name     ASC,
  s.full_name ASC;
