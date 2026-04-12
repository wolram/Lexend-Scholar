/**
 * Fixtures de teste — Escola, Usuários e Estrutura Acadêmica
 *
 * Fornece objetos prontos para uso em testes E2E e unitários do Lexend Scholar.
 * Os dados refletem o schema real do banco (database_schema.sql).
 */

// ─────────────────────────────────────────────────────────────────────────────
// Tipos alinhados ao schema Supabase
// ─────────────────────────────────────────────────────────────────────────────

export type PlanType = 'starter' | 'pro' | 'enterprise';
export type RoleType = 'admin' | 'teacher' | 'secretary' | 'guardian' | 'student';

export interface EscolaFixture {
  id: string;
  name: string;
  cnpj: string;
  email: string;
  phone: string;
  address: string;
  city: string;
  state: string;
  zip_code: string;
  plan: PlanType;
  max_students: number;
}

export interface UsuarioFixture {
  id: string;
  school_id: string;
  email: string;
  password: string; // apenas para seed — nunca armazenar no banco
  full_name: string;
  role: RoleType;
  active: boolean;
}

export interface AnoLetivoFixture {
  id: string;
  school_id: string;
  name: string;
  start_date: string;
  end_date: string;
  active: boolean;
}

export interface PeriodoFixture {
  id: string;
  school_id: string;
  academic_year_id: string;
  name: string;
  start_date: string;
  end_date: string;
}

export interface SerieFixture {
  id: string;
  school_id: string;
  name: string;
  level: string;
}

export interface TurmaFixture {
  id: string;
  school_id: string;
  grade_id: string;
  academic_year_id: string;
  name: string;
  shift: string;
  teacher_id: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// Escola de teste
// ─────────────────────────────────────────────────────────────────────────────

export const ESCOLA_FIXTURE: EscolaFixture = {
  id: 'a1b2c3d4-0001-0001-0001-000000000001',
  name: 'Escola Municipal São Francisco',
  cnpj: '12.345.678/0001-99',
  email: 'contato@escola-sf-test.com.br',
  phone: '(11) 3333-4444',
  address: 'Rua das Flores, 100',
  city: 'São Paulo',
  state: 'SP',
  zip_code: '01310-100',
  plan: 'pro',
  max_students: 500,
};

// ─────────────────────────────────────────────────────────────────────────────
// Usuários de teste (um por perfil)
// ─────────────────────────────────────────────────────────────────────────────

export const USUARIO_DIRETOR: UsuarioFixture = {
  id: 'a1b2c3d4-0001-0001-0001-000000000010',
  school_id: ESCOLA_FIXTURE.id,
  email: 'diretor@lexend-test.com.br',
  password: 'LexendTest@2025!',
  full_name: 'Carlos Eduardo Mendes',
  role: 'admin',
  active: true,
};

export const USUARIO_PROFESSOR: UsuarioFixture = {
  id: 'a1b2c3d4-0001-0001-0001-000000000011',
  school_id: ESCOLA_FIXTURE.id,
  email: 'professor@lexend-test.com.br',
  password: 'LexendTest@2025!',
  full_name: 'Dra. Sarah Jenkins',
  role: 'teacher',
  active: true,
};

export const USUARIO_SECRETARIO: UsuarioFixture = {
  id: 'a1b2c3d4-0001-0001-0001-000000000012',
  school_id: ESCOLA_FIXTURE.id,
  email: 'secretario@lexend-test.com.br',
  password: 'LexendTest@2025!',
  full_name: 'Ana Paula Ribeiro',
  role: 'secretary',
  active: true,
};

export const TODOS_USUARIOS: UsuarioFixture[] = [
  USUARIO_DIRETOR,
  USUARIO_PROFESSOR,
  USUARIO_SECRETARIO,
];

// ─────────────────────────────────────────────────────────────────────────────
// Estrutura acadêmica
// ─────────────────────────────────────────────────────────────────────────────

export const ANO_LETIVO_2025: AnoLetivoFixture = {
  id: 'a1b2c3d4-0001-0001-0001-000000000020',
  school_id: ESCOLA_FIXTURE.id,
  name: '2025',
  start_date: '2025-02-03',
  end_date: '2025-12-15',
  active: true,
};

export const PERIODOS_2025: PeriodoFixture[] = [
  {
    id: 'a1b2c3d4-0001-0001-0001-000000000030',
    school_id: ESCOLA_FIXTURE.id,
    academic_year_id: ANO_LETIVO_2025.id,
    name: '1º Bimestre',
    start_date: '2025-02-03',
    end_date: '2025-04-11',
  },
  {
    id: 'a1b2c3d4-0001-0001-0001-000000000031',
    school_id: ESCOLA_FIXTURE.id,
    academic_year_id: ANO_LETIVO_2025.id,
    name: '2º Bimestre',
    start_date: '2025-04-14',
    end_date: '2025-06-30',
  },
  {
    id: 'a1b2c3d4-0001-0001-0001-000000000032',
    school_id: ESCOLA_FIXTURE.id,
    academic_year_id: ANO_LETIVO_2025.id,
    name: '3º Bimestre',
    start_date: '2025-07-28',
    end_date: '2025-09-26',
  },
  {
    id: 'a1b2c3d4-0001-0001-0001-000000000033',
    school_id: ESCOLA_FIXTURE.id,
    academic_year_id: ANO_LETIVO_2025.id,
    name: '4º Bimestre',
    start_date: '2025-09-29',
    end_date: '2025-11-28',
  },
];

export const SERIES: SerieFixture[] = [
  {
    id: 'a1b2c3d4-0001-0001-0001-000000000040',
    school_id: ESCOLA_FIXTURE.id,
    name: '1º Ano EM',
    level: 'medio',
  },
  {
    id: 'a1b2c3d4-0001-0001-0001-000000000041',
    school_id: ESCOLA_FIXTURE.id,
    name: '2º Ano EM',
    level: 'medio',
  },
  {
    id: 'a1b2c3d4-0001-0001-0001-000000000042',
    school_id: ESCOLA_FIXTURE.id,
    name: '9º Ano EF',
    level: 'fundamental',
  },
];

export const TURMA_10A: TurmaFixture = {
  id: 'a1b2c3d4-0001-0001-0001-000000000050',
  school_id: ESCOLA_FIXTURE.id,
  grade_id: SERIES[0].id,
  academic_year_id: ANO_LETIVO_2025.id,
  name: '1º A',
  shift: 'morning',
  teacher_id: USUARIO_PROFESSOR.id,
};

export const TURMA_10B: TurmaFixture = {
  id: 'a1b2c3d4-0001-0001-0001-000000000051',
  school_id: ESCOLA_FIXTURE.id,
  grade_id: SERIES[0].id,
  academic_year_id: ANO_LETIVO_2025.id,
  name: '1º B',
  shift: 'afternoon',
  teacher_id: USUARIO_PROFESSOR.id,
};

export const TODAS_TURMAS: TurmaFixture[] = [TURMA_10A, TURMA_10B];

// ─────────────────────────────────────────────────────────────────────────────
// Helper: credenciais por papel para uso nos testes E2E
// ─────────────────────────────────────────────────────────────────────────────

export function credenciaisPorPapel(role: 'diretor' | 'professor' | 'secretario') {
  const map = {
    diretor: { email: USUARIO_DIRETOR.email, password: USUARIO_DIRETOR.password },
    professor: { email: USUARIO_PROFESSOR.email, password: USUARIO_PROFESSOR.password },
    secretario: { email: USUARIO_SECRETARIO.email, password: USUARIO_SECRETARIO.password },
  };
  return map[role];
}

// ─────────────────────────────────────────────────────────────────────────────
// Script de seed (para uso com ts-node direto)
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Retorna o SQL de seed completo para inserção no banco de staging.
 * Uso: npx ts-node tests/fixtures/escola.ts | psql $DATABASE_URL
 */
export function gerarSQLSeed(): string {
  return `
-- ================================================================
-- Seed de dados de teste — Lexend Scholar
-- Gerado por: tests/fixtures/escola.ts
-- Ambiente: staging/test
-- ================================================================

-- Escola
INSERT INTO schools (id, name, cnpj, email, phone, address, city, state, zip_code, plan, max_students)
VALUES (
  '${ESCOLA_FIXTURE.id}',
  '${ESCOLA_FIXTURE.name}',
  '${ESCOLA_FIXTURE.cnpj}',
  '${ESCOLA_FIXTURE.email}',
  '${ESCOLA_FIXTURE.phone}',
  '${ESCOLA_FIXTURE.address}',
  '${ESCOLA_FIXTURE.city}',
  '${ESCOLA_FIXTURE.state}',
  '${ESCOLA_FIXTURE.zip_code}',
  '${ESCOLA_FIXTURE.plan}',
  ${ESCOLA_FIXTURE.max_students}
) ON CONFLICT (id) DO NOTHING;

-- Usuários (autenticação via Supabase Auth — inserir no auth.users separadamente)
${TODOS_USUARIOS.map(u => `
INSERT INTO users (id, school_id, email, full_name, role, active)
VALUES ('${u.id}', '${u.school_id}', '${u.email}', '${u.full_name}', '${u.role}', ${u.active})
ON CONFLICT (id) DO NOTHING;`).join('')}

-- Ano letivo
INSERT INTO academic_years (id, school_id, name, start_date, end_date, active)
VALUES ('${ANO_LETIVO_2025.id}', '${ANO_LETIVO_2025.school_id}', '${ANO_LETIVO_2025.name}', '${ANO_LETIVO_2025.start_date}', '${ANO_LETIVO_2025.end_date}', ${ANO_LETIVO_2025.active})
ON CONFLICT (id) DO NOTHING;

-- Períodos bimestrais
${PERIODOS_2025.map(p => `
INSERT INTO academic_periods (id, school_id, academic_year_id, name, start_date, end_date)
VALUES ('${p.id}', '${p.school_id}', '${p.academic_year_id}', '${p.name}', '${p.start_date}', '${p.end_date}')
ON CONFLICT (id) DO NOTHING;`).join('')}

-- Séries
${SERIES.map(s => `
INSERT INTO grades (id, school_id, name, level)
VALUES ('${s.id}', '${s.school_id}', '${s.name}', '${s.level}')
ON CONFLICT (id) DO NOTHING;`).join('')}

-- Turmas
${TODAS_TURMAS.map(t => `
INSERT INTO classes (id, school_id, grade_id, academic_year_id, name, shift, teacher_id)
VALUES ('${t.id}', '${t.school_id}', '${t.grade_id}', '${t.academic_year_id}', '${t.name}', '${t.shift}', '${t.teacher_id}')
ON CONFLICT (id) DO NOTHING;`).join('')}
`;
}

if (require.main === module) {
  process.stdout.write(gerarSQLSeed());
}
