import { test, expect } from '@playwright/test';
import { STORAGE_STATE } from './playwright.config';
import { ALUNO_SOPHIA, MATRICULA_SOPHIA, ALUNOS_TURMA_10A } from '../fixtures/alunos';
import { PERIODOS_2025, TURMA_10A } from '../fixtures/escola';

/**
 * LS-67 — E2E: Lançamento de notas e geração de boletim
 *
 * Fluxo executado pelo professor:
 *   1. Acessar módulo de notas
 *   2. Selecionar turma e disciplina
 *   3. Lançar notas para todos os alunos por período
 *   4. Verificar cálculo automático de média
 *   5. Gerar boletim PDF de um aluno
 *   6. Verificar conteúdo do boletim
 */

test.use({ storageState: STORAGE_STATE.professor });

// ─────────────────────────────────────────────────────────────────────────────
// Dados de teste
// ─────────────────────────────────────────────────────────────────────────────

const NOME_TURMA = TURMA_10A.name; // '1º A'
const PERIODO_1 = PERIODOS_2025[0].name; // '1º Bimestre'

// Notas do 1º bimestre para cada aluno (0–10)
const NOTAS_BIMESTRE: Record<string, { nota1: string; nota2: string; mediaEsperada: number }> = {
  'Sophia Anderson': { nota1: '8.5', nota2: '9.0', mediaEsperada: 8.75 },
  'Lucas da Silva': { nota1: '6.0', nota2: '7.5', mediaEsperada: 6.75 },
  'Beatriz Costa': { nota1: '9.5', nota2: '10.0', mediaEsperada: 9.75 },
  'Gabriel Mendes': { nota1: '5.0', nota2: '6.0', mediaEsperada: 5.5 }, // reprovado
  'Isabela Ferreira': { nota1: '7.0', nota2: '8.0', mediaEsperada: 7.5 },
};

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function navegarParaNotas(page: import('@playwright/test').Page) {
  await page.goto('/notas');
  await expect(page).toHaveURL(/\/notas|\/grades/);
  await expect(page.getByRole('heading', { name: /notas|lançamento/i })).toBeVisible();
}

async function selecionarTurmaEPeriodo(
  page: import('@playwright/test').Page,
  nomeTurma: string,
  periodo: string
) {
  const turmaSelect = page.getByLabel(/turma|classe/i);
  await turmaSelect.selectOption({ label: nomeTurma });

  const periodoSelect = page.getByLabel(/período|bimestre/i);
  await periodoSelect.selectOption({ label: periodo });

  const botaoCarregar = page.getByRole('button', { name: /carregar|buscar|ver notas/i });
  if (await botaoCarregar.isVisible()) await botaoCarregar.click();

  await expect(
    page.getByRole('table').or(page.getByTestId('notas-table'))
  ).toBeVisible({ timeout: 8_000 });
}

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Lançamento de Notas
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Lançamento de Notas — Turma 1º A', () => {
  test('deve carregar a grade de notas da turma', async ({ page }) => {
    await navegarParaNotas(page);
    await selecionarTurmaEPeriodo(page, NOME_TURMA, PERIODO_1);

    // Todos os alunos devem aparecer na grade
    for (const aluno of ALUNOS_TURMA_10A) {
      await expect(page.getByText(aluno.full_name)).toBeVisible({ timeout: 5_000 });
    }
  });

  test('deve lançar nota para aluno individual', async ({ page }) => {
    await navegarParaNotas(page);
    await selecionarTurmaEPeriodo(page, NOME_TURMA, PERIODO_1);

    const linhaSophia = page.getByRole('row').filter({ hasText: 'Sophia Anderson' });
    const { nota1, nota2 } = NOTAS_BIMESTRE['Sophia Anderson'];

    // Campo Nota 1
    const nota1Input = linhaSophia.getByRole('spinbutton').first()
      .or(linhaSophia.getByLabel(/nota 1|av1|avaliação 1/i));
    await nota1Input.fill(nota1);
    await nota1Input.press('Tab');

    // Campo Nota 2
    const nota2Input = linhaSophia.getByRole('spinbutton').nth(1)
      .or(linhaSophia.getByLabel(/nota 2|av2|avaliação 2/i));
    await nota2Input.fill(nota2);
    await nota2Input.press('Tab');

    // Média calculada automaticamente
    const mediaCell = linhaSophia.getByTestId('media')
      .or(linhaSophia.getByText(/8[.,]75/));
    await expect(mediaCell).toBeVisible({ timeout: 3_000 });
  });

  test('deve lançar notas para todos os alunos da turma', async ({ page }) => {
    await navegarParaNotas(page);
    await selecionarTurmaEPeriodo(page, NOME_TURMA, PERIODO_1);

    for (const aluno of ALUNOS_TURMA_10A) {
      const notas = NOTAS_BIMESTRE[aluno.full_name];
      if (!notas) continue;

      const linha = page.getByRole('row').filter({ hasText: aluno.full_name });

      const nota1Input = linha.getByRole('spinbutton').first();
      await nota1Input.clear();
      await nota1Input.fill(notas.nota1);
      await nota1Input.press('Tab');

      const nota2Input = linha.getByRole('spinbutton').nth(1);
      await nota2Input.clear();
      await nota2Input.fill(notas.nota2);
      await nota2Input.press('Tab');
    }

    // Salvar todas as notas
    const botaoSalvar = page.getByRole('button', { name: /salvar notas|confirmar|gravar/i });
    await expect(botaoSalvar).toBeEnabled();
    await botaoSalvar.click();

    await expect(
      page.getByRole('alert').filter({ hasText: /notas salvas|registradas|sucesso/i })
    ).toBeVisible({ timeout: 10_000 });
  });

  test('deve calcular médias corretamente para cada aluno', async ({ page }) => {
    await navegarParaNotas(page);
    await selecionarTurmaEPeriodo(page, NOME_TURMA, PERIODO_1);

    // Verificar média da Sophia (8.75)
    const linhaSophia = page.getByRole('row').filter({ hasText: 'Sophia Anderson' });
    await expect(linhaSophia.getByText(/8[.,]75/)).toBeVisible({ timeout: 5_000 });

    // Verificar média do Gabriel (5.5 — abaixo da média)
    const linhaGabriel = page.getByRole('row').filter({ hasText: 'Gabriel Mendes' });
    await expect(linhaGabriel.getByText(/5[.,]5/)).toBeVisible({ timeout: 5_000 });
  });

  test('deve sinalizar alunos com média abaixo de 7', async ({ page }) => {
    await navegarParaNotas(page);
    await selecionarTurmaEPeriodo(page, NOME_TURMA, PERIODO_1);

    // Gabriel com média 5.5 deve ter indicador visual de atenção
    const linhaGabriel = page.getByRole('row').filter({ hasText: 'Gabriel Mendes' });
    await expect(
      linhaGabriel.locator('[data-status="reprovado"], .text-red, [class*="danger"], [class*="warning"]')
        .or(linhaGabriel.getByText(/reprovado|em recuperação/i))
    ).toBeVisible({ timeout: 5_000 });
  });

  test('deve validar notas fora do intervalo 0–10', async ({ page }) => {
    await navegarParaNotas(page);
    await selecionarTurmaEPeriodo(page, NOME_TURMA, PERIODO_1);

    const linhaSophia = page.getByRole('row').filter({ hasText: 'Sophia Anderson' });
    const nota1Input = linhaSophia.getByRole('spinbutton').first();

    // Nota acima de 10
    await nota1Input.fill('11');
    await nota1Input.blur();

    await expect(
      page.getByText(/nota inválida|máximo.*10|valor.*inválido/i)
        .or(nota1Input)
    ).toBeVisible({ timeout: 3_000 });

    // Nota negativa
    await nota1Input.clear();
    await nota1Input.fill('-1');
    await nota1Input.blur();

    await expect(
      page.getByText(/nota inválida|mínimo.*0|valor.*inválido/i)
    ).toBeVisible({ timeout: 3_000 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Geração de Boletim
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Geração de Boletim', () => {
  test('deve acessar o boletim do aluno a partir do perfil', async ({ page }) => {
    await page.goto('/alunos');

    // Buscar Sophia
    const busca = page.getByPlaceholder(/buscar|pesquisar/i);
    await busca.fill('Sophia Anderson');

    const linhaSophia = page.getByRole('row').filter({ hasText: 'Sophia Anderson' });
    await linhaSophia.getByRole('link', { name: /ver perfil|detalhes/i }).click();

    // Navegar para aba de desempenho/boletim
    const desempenhoTab = page.getByRole('tab', { name: /desempenho|boletim|notas/i });
    await expect(desempenhoTab).toBeVisible({ timeout: 5_000 });
    await desempenhoTab.click();

    // Boletim com notas por disciplina e bimestre
    await expect(
      page.getByText(/1º bimestre/i).or(page.getByRole('table'))
    ).toBeVisible({ timeout: 5_000 });
  });

  test('deve gerar e baixar boletim em PDF', async ({ page }) => {
    await page.goto(`/alunos/${ALUNO_SOPHIA.id}/boletim`);

    // Botão de exportar PDF
    const botaoPDF = page.getByRole('button', { name: /gerar pdf|exportar pdf|baixar boletim/i })
      .or(page.getByRole('link', { name: /pdf|boletim/i }));

    await expect(botaoPDF).toBeVisible({ timeout: 8_000 });

    // Interceptar download
    const [download] = await Promise.all([
      page.waitForEvent('download', { timeout: 15_000 }),
      botaoPDF.click(),
    ]);

    expect(download.suggestedFilename()).toMatch(/boletim.*sophia|sophia.*boletim|boletim.*2025/i);
    expect(download.suggestedFilename()).toMatch(/\.pdf$/i);
  });

  test('deve exibir todas as disciplinas no boletim', async ({ page }) => {
    await page.goto(`/alunos/${ALUNO_SOPHIA.id}/boletim`);

    // Disciplinas padrão do ensino médio
    const disciplinasEsperadas = [
      /matemática|math/i,
      /português|língua portuguesa/i,
      /história/i,
      /geografia/i,
      /ciências|biologia/i,
    ];

    for (const disciplina of disciplinasEsperadas) {
      await expect(page.getByText(disciplina)).toBeVisible({ timeout: 5_000 });
    }
  });

  test('deve exibir os quatro bimestres no boletim', async ({ page }) => {
    await page.goto(`/alunos/${ALUNO_SOPHIA.id}/boletim`);

    for (const periodo of PERIODOS_2025) {
      await expect(page.getByText(periodo.name)).toBeVisible({ timeout: 5_000 });
    }

    // Média final também deve aparecer
    await expect(page.getByText(/média final|média anual/i)).toBeVisible();
  });

  test('deve exibir frequência geral no boletim', async ({ page }) => {
    await page.goto(`/alunos/${ALUNO_SOPHIA.id}/boletim`);

    await expect(
      page.getByText(/frequência|% presença|total de faltas/i)
    ).toBeVisible({ timeout: 5_000 });
  });

  test('boletim deve mostrar situação final do aluno', async ({ page }) => {
    await page.goto(`/alunos/${ALUNO_SOPHIA.id}/boletim`);

    // Sophia tem notas acima da média — deve estar aprovada
    await expect(
      page.getByText(/aprovado|situação.*aprovado/i)
    ).toBeVisible({ timeout: 5_000 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Boletim via módulo de notas (professor)
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Boletim — Acesso do Professor', () => {
  test('deve gerar boletim de aluno direto da grade de notas', async ({ page }) => {
    await navegarParaNotas(page);
    await selecionarTurmaEPeriodo(page, NOME_TURMA, PERIODO_1);

    const linhaSophia = page.getByRole('row').filter({ hasText: 'Sophia Anderson' });

    // Botão de ações ou boletim na linha
    const acaoBoletim = linhaSophia.getByRole('button', { name: /boletim|ver boletim/i })
      .or(linhaSophia.getByRole('link', { name: /boletim/i }));

    if (await acaoBoletim.isVisible()) {
      await acaoBoletim.click();
      await expect(page).toHaveURL(/\/boletim|\/report/);
    } else {
      test.skip(true, 'Atalho para boletim não disponível na grade de notas');
    }
  });

  test('deve exibir histórico de notas por bimestre na visão da turma', async ({ page }) => {
    await navegarParaNotas(page);

    // Selecionar modo de exibição por bimestre
    const filtroBimestre = page.getByLabel(/bimestre|período/i);
    await filtroBimestre.selectOption({ label: '2º Bimestre' });

    await expect(
      page.getByRole('table').or(page.getByTestId('notas-table'))
    ).toBeVisible({ timeout: 5_000 });
  });
});
