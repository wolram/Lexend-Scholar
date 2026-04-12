-- ============================================================
-- Lexend Scholar — Relatório de Frequência
-- Referência: database_schema.sql
--   Tabelas: attendance_records, students, classes, subjects,
--            academic_periods, student_class_enrollments
--
-- Parâmetros:
--   :school_id        — UUID da escola (obrigatório)
--   :student_id       — UUID do aluno (NULL = todos os alunos)
--   :class_id         — UUID da turma (NULL = todas as turmas)
--   :date_start       — Data inicial do período (ex: '2025-02-01')
--   :date_end         — Data final do período   (ex: '2025-06-30')
-- ============================================================

-- ============================================================
-- 1. FREQUÊNCIA POR ALUNO (geral no período)
-- ============================================================
SELECT
  s.enrollment_code                                       AS matricula,
  s.full_name                                             AS aluno,
  c.name                                                  AS turma,
  g.name                                                  AS serie,
  COUNT(ar.id)                                            AS total_aulas,
  COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END) AS presencas,
  COUNT(CASE WHEN ar.status = 'absent'            THEN 1 END) AS faltas,
  COUNT(CASE WHEN ar.status = 'late'              THEN 1 END) AS atrasos,
  COUNT(CASE WHEN ar.status = 'excused'           THEN 1 END) AS faltas_justificadas,
  ROUND(
    COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END)::NUMERIC
    / NULLIF(COUNT(ar.id), 0) * 100, 1
  )                                                       AS frequencia_pct,
  CASE
    WHEN COUNT(ar.id) = 0 THEN 'Sem registro'
    WHEN COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END)::NUMERIC
         / NULLIF(COUNT(ar.id), 0) >= 0.75 THEN 'Regular'
    WHEN COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END)::NUMERIC
         / NULLIF(COUNT(ar.id), 0) >= 0.60 THEN 'Atenção'
    ELSE 'Crítico — Risco de reprovação'
  END                                                     AS status_frequencia
FROM students s
INNER JOIN student_class_enrollments sce ON sce.student_id = s.id AND sce.active = TRUE
INNER JOIN classes c                     ON c.id = sce.class_id
INNER JOIN grades g                      ON g.id = c.grade_id
LEFT JOIN  attendance_records ar
        ON ar.student_id = s.id
       AND ar.class_id   = c.id
       AND ar.school_id  = :school_id
       AND ar.date BETWEEN :date_start AND :date_end
WHERE s.school_id  = :school_id
  AND s.active     = TRUE
  AND (:student_id IS NULL OR s.id = :student_id::UUID)
  AND (:class_id   IS NULL OR c.id = :class_id::UUID)
GROUP BY s.id, s.enrollment_code, s.full_name, c.name, g.name
ORDER BY frequencia_pct ASC, s.full_name;

-- ============================================================
-- 2. FREQUÊNCIA POR TURMA (consolidado)
-- ============================================================
SELECT
  c.name                                                  AS turma,
  g.name                                                  AS serie,
  COUNT(DISTINCT s.id)                                    AS total_alunos,
  COUNT(ar.id)                                            AS total_registros,
  COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END) AS total_presencas,
  COUNT(CASE WHEN ar.status = 'absent'            THEN 1 END) AS total_faltas,
  ROUND(
    COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END)::NUMERIC
    / NULLIF(COUNT(ar.id), 0) * 100, 1
  )                                                       AS frequencia_media_pct,
  -- Alunos em risco (< 75%)
  COUNT(DISTINCT CASE
    WHEN (
      SELECT COUNT(CASE WHEN ar2.status IN ('present','late') THEN 1 END)::NUMERIC
           / NULLIF(COUNT(ar2.id), 0)
      FROM attendance_records ar2
      WHERE ar2.student_id = s.id AND ar2.class_id = c.id
        AND ar2.date BETWEEN :date_start AND :date_end
    ) < 0.75 THEN s.id
  END)                                                    AS alunos_em_risco
FROM classes c
INNER JOIN grades g                      ON g.id = c.grade_id
INNER JOIN student_class_enrollments sce ON sce.class_id = c.id AND sce.active = TRUE
INNER JOIN students s                    ON s.id = sce.student_id AND s.active = TRUE
LEFT JOIN  attendance_records ar
        ON ar.class_id  = c.id
       AND ar.student_id = s.id
       AND ar.school_id  = :school_id
       AND ar.date BETWEEN :date_start AND :date_end
WHERE c.school_id  = :school_id
  AND (:class_id IS NULL OR c.id = :class_id::UUID)
GROUP BY c.id, c.name, g.name
ORDER BY frequencia_media_pct ASC;

-- ============================================================
-- 3. FREQUÊNCIA POR DISCIPLINA (de uma turma ou de um aluno)
-- ============================================================
SELECT
  sub.name                                                AS disciplina,
  sub.code,
  COUNT(ar.id)                                            AS total_aulas,
  COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END) AS presencas,
  COUNT(CASE WHEN ar.status = 'absent'            THEN 1 END) AS faltas,
  ROUND(
    COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END)::NUMERIC
    / NULLIF(COUNT(ar.id), 0) * 100, 1
  )                                                       AS frequencia_pct
FROM attendance_records ar
INNER JOIN subjects sub ON sub.id = ar.subject_id
WHERE ar.school_id  = :school_id
  AND ar.date BETWEEN :date_start AND :date_end
  AND (:student_id IS NULL OR ar.student_id = :student_id::UUID)
  AND (:class_id   IS NULL OR ar.class_id   = :class_id::UUID)
GROUP BY sub.id, sub.name, sub.code
ORDER BY frequencia_pct ASC;

-- ============================================================
-- 4. FREQUÊNCIA DIÁRIA (calendário de presença de um aluno)
-- ============================================================
SELECT
  ar.date,
  TO_CHAR(ar.date, 'Day')                                 AS dia_semana,
  sub.name                                                AS disciplina,
  ar.status,
  ar.notes,
  u.full_name                                             AS registrado_por
FROM attendance_records ar
INNER JOIN subjects sub ON sub.id = ar.subject_id
LEFT JOIN  users u      ON u.id   = ar.recorded_by
WHERE ar.school_id  = :school_id
  AND ar.student_id = :student_id::UUID
  AND ar.date BETWEEN :date_start AND :date_end
ORDER BY ar.date, sub.name;

-- ============================================================
-- 5. ALUNOS COM FREQUÊNCIA CRÍTICA (< 60%) — ALERTA SECRETARIA
-- ============================================================
WITH freq_por_aluno AS (
  SELECT
    s.id                                                  AS student_id,
    s.enrollment_code,
    s.full_name,
    s.email,
    c.name                                                AS turma,
    g.name                                                AS serie,
    COUNT(ar.id)                                          AS total_aulas,
    COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END) AS presencas,
    ROUND(
      COUNT(CASE WHEN ar.status IN ('present','late') THEN 1 END)::NUMERIC
      / NULLIF(COUNT(ar.id), 0) * 100, 1
    )                                                     AS frequencia_pct
  FROM students s
  INNER JOIN student_class_enrollments sce ON sce.student_id = s.id AND sce.active = TRUE
  INNER JOIN classes c ON c.id = sce.class_id
  INNER JOIN grades g  ON g.id = c.grade_id
  LEFT JOIN  attendance_records ar
          ON ar.student_id = s.id AND ar.class_id = c.id
         AND ar.school_id  = :school_id
         AND ar.date BETWEEN :date_start AND :date_end
  WHERE s.school_id = :school_id AND s.active = TRUE
  GROUP BY s.id, s.enrollment_code, s.full_name, s.email, c.name, g.name
)
SELECT
  *,
  (total_aulas - presencas) AS faltas_totais,
  -- Faltas máximas permitidas (25% da carga horária)
  CEIL(total_aulas * 0.25)  AS faltas_permitidas,
  -- Faltas disponíveis até limite
  GREATEST(0, CEIL(total_aulas * 0.25) - (total_aulas - presencas)) AS faltas_restantes
FROM freq_por_aluno
WHERE frequencia_pct < 60 OR total_aulas = 0
ORDER BY frequencia_pct ASC;
