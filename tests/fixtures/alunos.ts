/**
 * Fixtures de teste — Alunos, Responsáveis e Matrículas
 *
 * Dados realistas para uso em testes E2E e unitários do Lexend Scholar.
 * Alinhados ao schema: students, guardians, enrollments.
 */

import { ESCOLA_FIXTURE, TURMA_10A, TURMA_10B, ANO_LETIVO_2025 } from './escola';

// ─────────────────────────────────────────────────────────────────────────────
// Tipos
// ─────────────────────────────────────────────────────────────────────────────

export type GenderType = 'M' | 'F' | 'other';
export type EnrollmentStatus = 'active' | 'transferred' | 'dropped' | 'graduated';

export interface ResponsavelFixture {
  id: string;
  school_id: string;
  full_name: string;
  relationship: string;
  email: string;
  phone: string;
  cpf: string;
}

export interface AlunoFixture {
  id: string;
  school_id: string;
  full_name: string;
  birth_date: string;
  gender: GenderType;
  cpf?: string;
  rg?: string;
  address: string;
  city: string;
  state: string;
  zip_code: string;
  guardian_id: string;
  photo_url?: string;
}

export interface MatriculaFixture {
  id: string;
  school_id: string;
  student_id: string;
  class_id: string;
  academic_year_id: string;
  enrollment_number: string;
  status: EnrollmentStatus;
  enrollment_date: string;
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsáveis
// ─────────────────────────────────────────────────────────────────────────────

export const RESPONSAVEL_ANDERSON: ResponsavelFixture = {
  id: 'a1b2c3d4-0002-0001-0001-000000000100',
  school_id: ESCOLA_FIXTURE.id,
  full_name: 'Robert Anderson',
  relationship: 'pai',
  email: 'r.anderson@email.com.br',
  phone: '(11) 99999-1001',
  cpf: '123.456.789-00',
};

export const RESPONSAVEL_SILVA: ResponsavelFixture = {
  id: 'a1b2c3d4-0002-0001-0001-000000000101',
  school_id: ESCOLA_FIXTURE.id,
  full_name: 'Maria José da Silva',
  relationship: 'mãe',
  email: 'mj.silva@email.com.br',
  phone: '(11) 99999-1002',
  cpf: '234.567.890-11',
};

export const RESPONSAVEL_COSTA: ResponsavelFixture = {
  id: 'a1b2c3d4-0002-0001-0001-000000000102',
  school_id: ESCOLA_FIXTURE.id,
  full_name: 'Paulo Rogério Costa',
  relationship: 'pai',
  email: 'pr.costa@email.com.br',
  phone: '(11) 99999-1003',
  cpf: '345.678.901-22',
};

// ─────────────────────────────────────────────────────────────────────────────
// Alunos
// ─────────────────────────────────────────────────────────────────────────────

export const ALUNO_SOPHIA: AlunoFixture = {
  id: 'a1b2c3d4-0002-0001-0001-000000000200',
  school_id: ESCOLA_FIXTURE.id,
  full_name: 'Sophia Anderson',
  birth_date: '2008-03-15',
  gender: 'F',
  cpf: '111.222.333-44',
  rg: '12.345.678-9',
  address: 'Av. Paulista, 1500, Apto 42',
  city: 'São Paulo',
  state: 'SP',
  zip_code: '01310-200',
  guardian_id: RESPONSAVEL_ANDERSON.id,
};

export const ALUNO_LUCAS: AlunoFixture = {
  id: 'a1b2c3d4-0002-0001-0001-000000000201',
  school_id: ESCOLA_FIXTURE.id,
  full_name: 'Lucas da Silva',
  birth_date: '2008-07-22',
  gender: 'M',
  cpf: '222.333.444-55',
  rg: '23.456.789-0',
  address: 'Rua Augusta, 200',
  city: 'São Paulo',
  state: 'SP',
  zip_code: '01305-000',
  guardian_id: RESPONSAVEL_SILVA.id,
};

export const ALUNO_BEATRIZ: AlunoFixture = {
  id: 'a1b2c3d4-0002-0001-0001-000000000202',
  school_id: ESCOLA_FIXTURE.id,
  full_name: 'Beatriz Costa',
  birth_date: '2008-11-05',
  gender: 'F',
  cpf: '333.444.555-66',
  address: 'Rua Consolação, 750',
  city: 'São Paulo',
  state: 'SP',
  zip_code: '01302-000',
  guardian_id: RESPONSAVEL_COSTA.id,
};

export const ALUNO_GABRIEL: AlunoFixture = {
  id: 'a1b2c3d4-0002-0001-0001-000000000203',
  school_id: ESCOLA_FIXTURE.id,
  full_name: 'Gabriel Mendes',
  birth_date: '2009-01-18',
  gender: 'M',
  cpf: '444.555.666-77',
  address: 'Alameda Santos, 320',
  city: 'São Paulo',
  state: 'SP',
  zip_code: '01419-000',
  guardian_id: RESPONSAVEL_ANDERSON.id, // irmão de Sophia (mesmo responsável)
};

export const ALUNO_ISABELA: AlunoFixture = {
  id: 'a1b2c3d4-0002-0001-0001-000000000204',
  school_id: ESCOLA_FIXTURE.id,
  full_name: 'Isabela Ferreira',
  birth_date: '2008-09-30',
  gender: 'F',
  cpf: '555.666.777-88',
  address: 'Rua Bela Cintra, 1000',
  city: 'São Paulo',
  state: 'SP',
  zip_code: '01415-001',
  guardian_id: RESPONSAVEL_SILVA.id,
};

/** Todos os alunos da turma 1º A */
export const ALUNOS_TURMA_10A: AlunoFixture[] = [
  ALUNO_SOPHIA,
  ALUNO_LUCAS,
  ALUNO_BEATRIZ,
  ALUNO_GABRIEL,
  ALUNO_ISABELA,
];

/** Aluno para testes de cadastro (novo — não matriculado) */
export const ALUNO_NOVO_PARA_CADASTRO: Omit<AlunoFixture, 'id'> & { id?: string } = {
  school_id: ESCOLA_FIXTURE.id,
  full_name: 'Fernando Oliveira Souza',
  birth_date: '2009-04-12',
  gender: 'M',
  cpf: '666.777.888-99',
  rg: '34.567.890-1',
  address: 'Rua Oscar Freire, 450',
  city: 'São Paulo',
  state: 'SP',
  zip_code: '01426-001',
  guardian_id: RESPONSAVEL_COSTA.id,
};

// ─────────────────────────────────────────────────────────────────────────────
// Matrículas
// ─────────────────────────────────────────────────────────────────────────────

export const MATRICULAS_TURMA_10A: MatriculaFixture[] = ALUNOS_TURMA_10A.map((aluno, idx) => ({
  id: `a1b2c3d4-0002-0003-0001-${String(idx + 1).padStart(12, '0')}`,
  school_id: ESCOLA_FIXTURE.id,
  student_id: aluno.id,
  class_id: TURMA_10A.id,
  academic_year_id: ANO_LETIVO_2025.id,
  enrollment_number: `2025-${String(1000 + idx + 1)}`,
  status: 'active' as EnrollmentStatus,
  enrollment_date: '2025-02-01',
}));

/** Matrícula da Sophia — referência direta para testes específicos */
export const MATRICULA_SOPHIA = MATRICULAS_TURMA_10A[0];

// ─────────────────────────────────────────────────────────────────────────────
// Helpers para testes
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Retorna um aluno pelo nome (busca parcial, case-insensitive).
 */
export function encontrarAluno(nome: string): AlunoFixture | undefined {
  return ALUNOS_TURMA_10A.find(a =>
    a.full_name.toLowerCase().includes(nome.toLowerCase())
  );
}

/**
 * Retorna a matrícula de um aluno pelo ID do aluno.
 */
export function encontrarMatricula(alunoId: string): MatriculaFixture | undefined {
  return MATRICULAS_TURMA_10A.find(m => m.student_id === alunoId);
}

/**
 * Gera SQL de seed para alunos, responsáveis e matrículas.
 */
export function gerarSQLSeedAlunos(): string {
  const responsaveis = [RESPONSAVEL_ANDERSON, RESPONSAVEL_SILVA, RESPONSAVEL_COSTA];

  return `
-- ================================================================
-- Seed: Alunos, Responsáveis e Matrículas
-- Gerado por: tests/fixtures/alunos.ts
-- ================================================================

-- Responsáveis
${responsaveis.map(r => `
INSERT INTO guardians (id, school_id, full_name, relationship, email, phone, cpf)
VALUES ('${r.id}', '${r.school_id}', '${r.full_name}', '${r.relationship}', '${r.email}', '${r.phone}', '${r.cpf}')
ON CONFLICT (id) DO NOTHING;`).join('')}

-- Alunos
${ALUNOS_TURMA_10A.map(a => `
INSERT INTO students (id, school_id, full_name, birth_date, gender, cpf, address, city, state, zip_code, guardian_id)
VALUES (
  '${a.id}', '${a.school_id}', '${a.full_name}', '${a.birth_date}',
  '${a.gender}', ${a.cpf ? `'${a.cpf}'` : 'NULL'},
  '${a.address}', '${a.city}', '${a.state}', '${a.zip_code}', '${a.guardian_id}'
) ON CONFLICT (id) DO NOTHING;`).join('')}

-- Matrículas
${MATRICULAS_TURMA_10A.map(m => `
INSERT INTO enrollments (id, school_id, student_id, class_id, academic_year_id, enrollment_number, status, enrollment_date)
VALUES ('${m.id}', '${m.school_id}', '${m.student_id}', '${m.class_id}', '${m.academic_year_id}', '${m.enrollment_number}', '${m.status}', '${m.enrollment_date}')
ON CONFLICT (id) DO NOTHING;`).join('')}
`;
}

if (require.main === module) {
  process.stdout.write(gerarSQLSeedAlunos());
}
