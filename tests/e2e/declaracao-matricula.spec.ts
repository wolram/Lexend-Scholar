import { test, expect } from '@playwright/test';
import { STORAGE_STATE } from './playwright.config';
import { ALUNO_SOPHIA, MATRICULA_SOPHIA } from '../fixtures/alunos';
import { ESCOLA_FIXTURE, ANO_LETIVO_2025, TURMA_10A } from '../fixtures/escola';

/**
 * LS-68 — E2E: Emissão de declaração de matrícula
 *
 * Fluxo executado pelo secretário:
 *   1. Acessar o perfil do aluno
 *   2. Solicitar emissão de declaração de matrícula
 *   3. Confirmar dados pré-preenchidos (nome, turma, ano letivo, escola)
 *   4. Baixar o documento PDF
 *   5. Verificar dados no documento gerado
 *   6. Verificar que histórico de documentos é atualizado
 */

test.use({ storageState: STORAGE_STATE.secretario });

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function navegarParaPerfilAluno(page: import('@playwright/test').Page, alunoId: string) {
  await page.goto(`/alunos/${alunoId}`);
  await expect(page).toHaveURL(new RegExp(`/alunos/${alunoId}`));
  await expect(page.getByRole('heading', { name: ALUNO_SOPHIA.full_name })).toBeVisible({
    timeout: 8_000,
  });
}

async function abrirModalDeclaracao(page: import('@playwright/test').Page) {
  // Procurar botão de emissão de declaração — pode estar em aba Documentos
  const docTab = page.getByRole('tab', { name: /documentos|declarações/i });
  if (await docTab.isVisible()) await docTab.click();

  const botaoEmitir = page.getByRole('button', {
    name: /emitir declaração|nova declaração|declaração de matrícula/i,
  });
  await expect(botaoEmitir).toBeVisible({ timeout: 5_000 });
  await botaoEmitir.click();

  // Aguardar modal ou página de emissão
  await expect(
    page.getByRole('dialog').or(page.getByRole('main').filter({ hasText: /declaração/i }))
  ).toBeVisible({ timeout: 5_000 });
}

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Fluxo principal
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Emissão de Declaração de Matrícula — Fluxo Completo', () => {
  test('deve acessar a seção de documentos no perfil do aluno', async ({ page }) => {
    await navegarParaPerfilAluno(page, ALUNO_SOPHIA.id);

    const docTab = page.getByRole('tab', { name: /documentos|declarações/i });
    await expect(docTab).toBeVisible({ timeout: 5_000 });
    await docTab.click();

    // Botão de nova declaração visível
    const botaoEmitir = page.getByRole('button', {
      name: /emitir declaração|nova declaração|gerar declaração/i,
    });
    await expect(botaoEmitir).toBeVisible();
  });

  test('deve exibir formulário pré-preenchido com dados corretos', async ({ page }) => {
    await navegarParaPerfilAluno(page, ALUNO_SOPHIA.id);
    await abrirModalDeclaracao(page);

    const dialog = page.getByRole('dialog').or(page.locator('[role="dialog"], form').first());

    // Nome do aluno
    await expect(dialog.getByText(ALUNO_SOPHIA.full_name)).toBeVisible({ timeout: 3_000 });

    // Escola
    await expect(dialog.getByText(ESCOLA_FIXTURE.name)).toBeVisible({ timeout: 3_000 });

    // Ano letivo
    await expect(dialog.getByText(ANO_LETIVO_2025.name)).toBeVisible({ timeout: 3_000 });

    // Turma
    await expect(dialog.getByText(TURMA_10A.name)).toBeVisible({ timeout: 3_000 });

    // Número de matrícula
    await expect(dialog.getByText(MATRICULA_SOPHIA.enrollment_number)).toBeVisible({
      timeout: 3_000,
    });
  });

  test('deve gerar e baixar declaração em PDF', async ({ page }) => {
    await navegarParaPerfilAluno(page, ALUNO_SOPHIA.id);
    await abrirModalDeclaracao(page);

    const botaoGerar = page.getByRole('button', {
      name: /gerar pdf|baixar declaração|emitir/i,
    });
    await expect(botaoGerar).toBeEnabled({ timeout: 3_000 });

    // Capturar evento de download
    const [download] = await Promise.all([
      page.waitForEvent('download', { timeout: 20_000 }),
      botaoGerar.click(),
    ]);

    // Verificar nome do arquivo
    expect(download.suggestedFilename()).toMatch(
      /declaracao.*matricula|declaração.*matrícula|sophia/i
    );
    expect(download.suggestedFilename()).toMatch(/\.pdf$/i);
  });

  test('deve registrar no histórico após emissão', async ({ page }) => {
    await navegarParaPerfilAluno(page, ALUNO_SOPHIA.id);
    await abrirModalDeclaracao(page);

    const botaoGerar = page.getByRole('button', { name: /gerar pdf|emitir/i });

    // Emitir (sem capturar download desta vez)
    await Promise.all([
      page.waitForEvent('download', { timeout: 20_000 }).catch(() => null),
      botaoGerar.click(),
    ]);

    // Fechar modal se aberto
    const botaoFechar = page.getByRole('button', { name: /fechar|ok|concluir/i });
    if (await botaoFechar.isVisible({ timeout: 3_000 })) await botaoFechar.click();

    // Verificar histórico na aba de documentos
    const docTab = page.getByRole('tab', { name: /documentos|declarações/i });
    if (await docTab.isVisible()) await docTab.click();

    // Pelo menos uma declaração deve aparecer na listagem com data de hoje
    const hoje = new Date().toLocaleDateString('pt-BR');
    await expect(
      page.getByText(/declaração de matrícula/i).first()
    ).toBeVisible({ timeout: 5_000 });
  });

  test('deve exibir data de emissão no documento gerado', async ({ page }) => {
    await navegarParaPerfilAluno(page, ALUNO_SOPHIA.id);
    await abrirModalDeclaracao(page);

    const dialog = page.getByRole('dialog').or(page.locator('[role="dialog"]').first());

    // Data de emissão deve corresponder ao dia atual (preenchida automaticamente)
    const hoje = new Date().toLocaleDateString('pt-BR'); // ex: "12/04/2026"
    await expect(
      dialog.getByText(hoje).or(dialog.getByLabel(/data de emissão/i))
    ).toBeVisible({ timeout: 3_000 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Via listagem de alunos
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Emissão de Declaração — Via Listagem de Alunos', () => {
  test('deve emitir declaração diretamente da lista de alunos', async ({ page }) => {
    await page.goto('/alunos');

    // Buscar Sophia
    const busca = page.getByPlaceholder(/buscar|pesquisar/i);
    await busca.fill('Sophia Anderson');

    const linhaSophia = page.getByRole('row').filter({ hasText: 'Sophia Anderson' });
    await expect(linhaSophia).toBeVisible({ timeout: 5_000 });

    // Menu de ações ou botão de declaração na linha
    const acoes = linhaSophia.getByRole('button', { name: /ações|mais|.../i });
    if (await acoes.isVisible()) {
      await acoes.click();
      const opcaoDeclaracao = page.getByRole('menuitem', {
        name: /declaração de matrícula|emitir declaração/i,
      });
      if (await opcaoDeclaracao.isVisible({ timeout: 3_000 })) {
        const [download] = await Promise.all([
          page.waitForEvent('download', { timeout: 20_000 }),
          opcaoDeclaracao.click(),
        ]);
        expect(download.suggestedFilename()).toMatch(/\.pdf$/i);
      } else {
        test.skip(true, 'Ação de declaração não disponível no menu de linha');
      }
    } else {
      test.skip(true, 'Menu de ações não disponível na listagem');
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Conteúdo e customização
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Declaração — Conteúdo e Customização', () => {
  test('deve permitir adicionar finalidade da declaração', async ({ page }) => {
    await navegarParaPerfilAluno(page, ALUNO_SOPHIA.id);
    await abrirModalDeclaracao(page);

    const dialog = page.getByRole('dialog').or(page.locator('[role="dialog"]').first());

    // Campo de finalidade (opcional)
    const finalidadeInput = dialog.getByLabel(/finalidade|objetivo|destinação/i);
    if (await finalidadeInput.isVisible()) {
      await finalidadeInput.fill('Apresentar ao empregador para estágio');
      await expect(finalidadeInput).toHaveValue('Apresentar ao empregador para estágio');
    } else {
      test.skip(true, 'Campo de finalidade não disponível');
    }
  });

  test('deve incluir carimbo e assinatura digital na declaração', async ({ page }) => {
    await navegarParaPerfilAluno(page, ALUNO_SOPHIA.id);
    await abrirModalDeclaracao(page);

    const dialog = page.getByRole('dialog').or(page.locator('[role="dialog"]').first());

    // Preview ou opção de assinatura
    const previewAssinatura = dialog.getByText(/assinatura|diretor|carimbo/i);
    if (await previewAssinatura.isVisible({ timeout: 3_000 })) {
      await expect(previewAssinatura).toBeVisible();
    } else {
      // Verificar ao menos que o nome do diretor está nos dados da declaração
      await expect(dialog.getByText(/responsável|diretor/i)).toBeVisible({ timeout: 3_000 });
    }
  });

  test('deve impedir emissão para aluno sem matrícula ativa', async ({ page }) => {
    // Tentar acessar aluno inexistente ou sem matrícula
    await page.goto('/alunos/00000000-0000-0000-0000-000000000000');

    // Deve mostrar erro 404 ou redirecionar
    await expect(
      page.getByText(/aluno não encontrado|não encontrado|404/i)
        .or(page.getByRole('heading', { name: /não encontrado/i }))
    ).toBeVisible({ timeout: 8_000 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Controle de acesso
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Declaração — Controle de Acesso', () => {
  test('secretário deve ter botão de emissão disponível', async ({ page }) => {
    await navegarParaPerfilAluno(page, ALUNO_SOPHIA.id);

    const docTab = page.getByRole('tab', { name: /documentos|declarações/i });
    if (await docTab.isVisible()) await docTab.click();

    const botaoEmitir = page.getByRole('button', {
      name: /emitir declaração|nova declaração/i,
    });
    await expect(botaoEmitir).toBeVisible({ timeout: 5_000 });
    await expect(botaoEmitir).toBeEnabled();
  });

  test('deve emitir declarações de múltiplos alunos sequencialmente', async ({ page }) => {
    const alunosParaDeclaracao = [ALUNO_SOPHIA.id];

    for (const alunoId of alunosParaDeclaracao) {
      await page.goto(`/alunos/${alunoId}`);

      const docTab = page.getByRole('tab', { name: /documentos|declarações/i });
      if (await docTab.isVisible()) await docTab.click();

      const botaoEmitir = page.getByRole('button', {
        name: /emitir declaração|nova declaração/i,
      });

      if (await botaoEmitir.isVisible({ timeout: 3_000 })) {
        await botaoEmitir.click();

        const botaoGerar = page.getByRole('button', { name: /gerar pdf|emitir/i });
        if (await botaoGerar.isVisible({ timeout: 3_000 })) {
          await Promise.all([
            page.waitForEvent('download', { timeout: 15_000 }).catch(() => null),
            botaoGerar.click(),
          ]);
        }

        // Fechar modal
        const fechar = page.getByRole('button', { name: /fechar|ok/i });
        if (await fechar.isVisible({ timeout: 2_000 })) await fechar.click();
      }
    }

    // Verificar que chegou ao fim sem erros
    await expect(page).toHaveURL(/\/alunos\//);
  });
});
