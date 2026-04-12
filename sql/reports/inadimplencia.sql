-- ============================================================
-- Lexend Scholar — Relatório de Inadimplência Financeira
-- Referência: database_schema.sql (tabelas: financial_records, students, schools)
--
-- Parâmetros (substituir antes de executar):
--   :school_id   UUID da escola
--   :date_ref    Data de referência (DEFAULT: CURRENT_DATE)
--   :min_days    Dias mínimos de atraso para incluir (DEFAULT: 1)
-- ============================================================

-- ============================================================
-- 1. VISÃO GERAL DE INADIMPLÊNCIA (resumo por faixa de atraso)
-- ============================================================
SELECT
  CASE
    WHEN (CURRENT_DATE - fr.due_date) BETWEEN 1  AND 30  THEN '1-30 dias'
    WHEN (CURRENT_DATE - fr.due_date) BETWEEN 31 AND 60  THEN '31-60 dias'
    WHEN (CURRENT_DATE - fr.due_date) BETWEEN 61 AND 90  THEN '61-90 dias'
    WHEN (CURRENT_DATE - fr.due_date) > 90               THEN 'Mais de 90 dias'
  END                                            AS faixa_atraso,
  COUNT(DISTINCT fr.student_id)                  AS num_alunos,
  COUNT(fr.id)                                   AS num_parcelas,
  SUM(fr.amount)                                 AS total_em_aberto,
  ROUND(AVG(CURRENT_DATE - fr.due_date), 1)      AS media_dias_atraso
FROM financial_records fr
WHERE fr.school_id    = :school_id
  AND fr.payment_status = 'pending'
  AND fr.due_date     < CURRENT_DATE
GROUP BY faixa_atraso
ORDER BY MIN(CURRENT_DATE - fr.due_date);

-- ============================================================
-- 2. LISTAGEM DETALHADA DE INADIMPLENTES
-- ============================================================
SELECT
  s.enrollment_code                              AS matricula,
  s.full_name                                    AS aluno,
  s.email                                        AS email_aluno,
  -- Responsável (primeiro guardian registrado)
  g.full_name                                    AS responsavel,
  g.phone                                        AS telefone_responsavel,
  g.email                                        AS email_responsavel,
  -- Dados financeiros
  fr.description                                 AS descricao_cobranca,
  fr.amount                                      AS valor,
  fr.due_date                                    AS vencimento,
  (CURRENT_DATE - fr.due_date)                   AS dias_atraso,
  -- Classificação do risco
  CASE
    WHEN (CURRENT_DATE - fr.due_date) <= 30  THEN 'Baixo'
    WHEN (CURRENT_DATE - fr.due_date) <= 60  THEN 'Médio'
    WHEN (CURRENT_DATE - fr.due_date) <= 90  THEN 'Alto'
    ELSE                                          'Crítico'
  END                                            AS risco,
  -- Total em aberto para o aluno
  SUM(fr.amount) OVER (PARTITION BY fr.student_id) AS total_divida_aluno,
  COUNT(fr.id)   OVER (PARTITION BY fr.student_id) AS num_parcelas_em_atraso
FROM financial_records fr
INNER JOIN students s
        ON s.id = fr.student_id
        AND s.school_id = fr.school_id
LEFT JOIN student_guardians sg ON sg.student_id = s.id
LEFT JOIN guardians g
        ON g.id = sg.guardian_id
        AND g.school_id = fr.school_id
WHERE fr.school_id    = :school_id
  AND fr.payment_status = 'pending'
  AND fr.due_date     < CURRENT_DATE
  AND (CURRENT_DATE - fr.due_date) >= :min_days
ORDER BY dias_atraso DESC, s.full_name;

-- ============================================================
-- 3. RANKING DE ALUNOS COM MAIOR DÍVIDA
-- ============================================================
SELECT
  s.enrollment_code                              AS matricula,
  s.full_name                                    AS aluno,
  COUNT(fr.id)                                   AS parcelas_em_atraso,
  SUM(fr.amount)                                 AS total_em_aberto,
  MAX(CURRENT_DATE - fr.due_date)                AS max_dias_atraso,
  MIN(fr.due_date)                               AS cobranca_mais_antiga
FROM financial_records fr
INNER JOIN students s ON s.id = fr.student_id
WHERE fr.school_id    = :school_id
  AND fr.payment_status = 'pending'
  AND fr.due_date     < CURRENT_DATE
GROUP BY s.id, s.enrollment_code, s.full_name
ORDER BY total_em_aberto DESC
LIMIT 20;

-- ============================================================
-- 4. EVOLUÇÃO MENSAL DA INADIMPLÊNCIA (últimos 12 meses)
-- ============================================================
WITH monthly AS (
  SELECT
    DATE_TRUNC('month', fr.due_date)::DATE        AS mes,
    COUNT(fr.id)                                   AS total_cobrado,
    COUNT(CASE WHEN fr.payment_status = 'paid'    THEN 1 END) AS total_pago,
    COUNT(CASE WHEN fr.payment_status = 'pending'
               AND fr.due_date < CURRENT_DATE     THEN 1 END) AS total_inadimplente,
    SUM(fr.amount)                                 AS valor_total,
    SUM(CASE WHEN fr.payment_status = 'paid'      THEN fr.amount ELSE 0 END) AS valor_recebido,
    SUM(CASE WHEN fr.payment_status = 'pending'
             AND fr.due_date < CURRENT_DATE       THEN fr.amount ELSE 0 END) AS valor_inadimplente
  FROM financial_records fr
  WHERE fr.school_id = :school_id
    AND fr.due_date >= CURRENT_DATE - INTERVAL '12 months'
  GROUP BY DATE_TRUNC('month', fr.due_date)
)
SELECT
  mes,
  total_cobrado,
  total_pago,
  total_inadimplente,
  ROUND(valor_total, 2)                           AS valor_total,
  ROUND(valor_recebido, 2)                        AS valor_recebido,
  ROUND(valor_inadimplente, 2)                    AS valor_inadimplente,
  ROUND(
    CASE WHEN valor_total > 0
    THEN (valor_inadimplente / valor_total * 100)
    ELSE 0 END, 1
  )                                               AS taxa_inadimplencia_pct
FROM monthly
ORDER BY mes;

-- ============================================================
-- 5. ÍNDICE GERAL DE INADIMPLÊNCIA DA ESCOLA
-- ============================================================
SELECT
  COUNT(DISTINCT CASE WHEN fr.payment_status = 'pending'
                      AND fr.due_date < CURRENT_DATE
                      THEN fr.student_id END)      AS alunos_inadimplentes,
  COUNT(DISTINCT s.id)                             AS total_alunos_ativos,
  ROUND(
    COUNT(DISTINCT CASE WHEN fr.payment_status = 'pending'
                        AND fr.due_date < CURRENT_DATE
                        THEN fr.student_id END)::NUMERIC
    / NULLIF(COUNT(DISTINCT s.id), 0) * 100, 1
  )                                                AS taxa_inadimplencia_pct,
  SUM(CASE WHEN fr.payment_status = 'pending'
           AND fr.due_date < CURRENT_DATE
           THEN fr.amount ELSE 0 END)              AS total_inadimplente_brl
FROM students s
LEFT JOIN financial_records fr
       ON fr.student_id = s.id AND fr.school_id = s.school_id
WHERE s.school_id = :school_id
  AND s.active = TRUE;
