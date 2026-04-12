import { test, expect } from '@playwright/test';
import { STORAGE_STATE } from './playwright.config';
import { ALUNO_NOVO_PARA_CADASTRO, RESPONSAVEL_COSTA, TURMA_10A } from '../fixtures/alunos';

/**
 * LS-65 — E2E: Cadastro completo de aluno
 *
 * Fluxo completo executado pelo secretário:
 *   1. Acessar o módulo de alunos
 *   2. Iniciar novo cadastro
 *   3. Preencher dados pessoais do aluno
 *   4. Vincular responsável (existente ou novo)
 *   5. Realizar matrícula em turma
 *   6. Confirmar criação e verificar no diretório
 */

// Reutiliza a sessão autenticada do secretário
test.use({ storageState: STORAGE_STATE.secretario });

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function navegarParaNovoAluno(page: import('@playwright/test').Page) {
  await page.goto('/alunos');
  await expect(page).toHaveURL(/\/alunos/);

  const botaoNovo = page.getByRole('button', { name: /novo aluno|adicionar aluno|cadastrar/i });
  await expect(botaoNovo).toBeVisible();
  await botaoNovo.click();

  // Aguardar modal ou página de cadastro
  await expect(
    page.getByRole('dialog').or(page.getByRole('main'))
  ).toContainText(/cadastro|novo aluno/i, { timeout: 5_000 });
}

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Fluxo principal de cadastro
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Cadastro de Aluno — Fluxo Completo', () => {
  test('deve preencher e salvar dados pessoais do aluno', async ({ page }) => {
    await navegarParaNovoAluno(page);

    // ── Aba/seção: Dados Pessoais ──────────────────────────────────────
    const dadosPessoaisTab = page.getByRole('tab', { name: /dados pessoais/i });
    if (await dadosPessoaisTab.isVisible()) await dadosPessoaisTab.click();

    await page.getByLabel(/nome completo/i).fill(ALUNO_NOVO_PARA_CADASTRO.full_name);

    // Data de nascimento
    await page.getByLabel(/data de nascimento|nascimento/i).fill('12/04/2009');

    // Sexo/Gênero
    const generoSelect = page.getByLabel(/sexo|gênero/i);
    await generoSelect.selectOption({ label: /masculino/i });

    // CPF
    if (ALUNO_NOVO_PARA_CADASTRO.cpf) {
      await page.getByLabel(/cpf/i).fill(ALUNO_NOVO_PARA_CADASTRO.cpf);
    }

    // RG
    if (ALUNO_NOVO_PARA_CADASTRO.rg) {
      await page.getByLabel(/rg/i).fill(ALUNO_NOVO_PARA_CADASTRO.rg);
    }

    // Verificar que os dados foram preenchidos corretamente
    await expect(page.getByLabel(/nome completo/i)).toHaveValue(ALUNO_NOVO_PARA_CADASTRO.full_name);
  });

  test('deve preencher o endereço do aluno', async ({ page }) => {
    await navegarParaNovoAluno(page);

    // Preencher dados pessoais mínimos primeiro
    await page.getByLabel(/nome completo/i).fill(ALUNO_NOVO_PARA_CADASTRO.full_name);

    // Navegar para aba de endereço
    const enderecoTab = page.getByRole('tab', { name: /endereço/i });
    if (await enderecoTab.isVisible()) {
      await enderecoTab.click();
    }

    // CEP com máscara
    const cepInput = page.getByLabel(/cep/i);
    await cepInput.fill('01426001');
    // Aguardar possível preenchimento automático via API de CEP
    await page.waitForTimeout(1_500);

    // Preencher campos manualmente caso autopreenchimento não funcione
    const enderecoInput = page.getByLabel(/endereço|logradouro/i);
    const currentValue = await enderecoInput.inputValue();
    if (!currentValue) {
      await enderecoInput.fill(ALUNO_NOVO_PARA_CADASTRO.address);
    }

    const cidadeInput = page.getByLabel(/cidade/i);
    const currentCidade = await cidadeInput.inputValue();
    if (!currentCidade) {
      await cidadeInput.fill(ALUNO_NOVO_PARA_CADASTRO.city);
    }

    const estadoSelect = page.getByLabel(/estado|uf/i);
    await estadoSelect.selectOption({ value: 'SP' });

    await expect(estadoSelect).toHaveValue('SP');
  });

  test('deve vincular responsável existente ao aluno', async ({ page }) => {
    await navegarParaNovoAluno(page);

    // Ir para aba de responsável
    const responsavelTab = page.getByRole('tab', { name: /responsável/i });
    if (await responsavelTab.isVisible()) {
      await responsavelTab.click();
    }

    // Buscar responsável existente pelo nome ou CPF
    const buscaResponsavel = page.getByPlaceholder(/buscar responsável|pesquisar/i);
    if (await buscaResponsavel.isVisible()) {
      await buscaResponsavel.fill(RESPONSAVEL_COSTA.full_name);
      await page.keyboard.press('Enter');

      // Selecionar da lista de resultados
      const opcaoResponsavel = page.getByRole('option', { name: RESPONSAVEL_COSTA.full_name })
        .or(page.getByText(RESPONSAVEL_COSTA.full_name).first());
      await expect(opcaoResponsavel).toBeVisible({ timeout: 5_000 });
      await opcaoResponsavel.click();
    }

    await expect(page.getByText(RESPONSAVEL_COSTA.full_name)).toBeVisible();
  });

  test('deve realizar matrícula em turma durante o cadastro', async ({ page }) => {
    await navegarParaNovoAluno(page);

    // Ir para aba de matrícula
    const matriculaTab = page.getByRole('tab', { name: /matrícula/i });
    if (await matriculaTab.isVisible()) {
      await matriculaTab.click();
    }

    // Selecionar ano letivo
    const anoLetivoSelect = page.getByLabel(/ano letivo/i);
    await anoLetivoSelect.selectOption({ label: '2025' });

    // Selecionar turma
    const turmaSelect = page.getByLabel(/turma|classe/i);
    await turmaSelect.selectOption({ label: TURMA_10A.name });

    // Verificar número de matrícula gerado automaticamente
    const numMatricula = page.getByLabel(/número de matrícula|nº matrícula/i);
    await expect(numMatricula).not.toBeEmpty({ timeout: 3_000 });
  });

  test('deve completar o cadastro e aparecer na listagem', async ({ page }) => {
    await navegarParaNovoAluno(page);

    // ── Dados pessoais ────────────────────────────────────────────────
    await page.getByLabel(/nome completo/i).fill(ALUNO_NOVO_PARA_CADASTRO.full_name);
    await page.getByLabel(/data de nascimento|nascimento/i).fill('12/04/2009');

    const generoSelect = page.getByLabel(/sexo|gênero/i);
    await generoSelect.selectOption({ label: /masculino/i });

    // ── Responsável (selecionar ou pular para mínimo viável) ──────────
    const responsavelTab = page.getByRole('tab', { name: /responsável/i });
    if (await responsavelTab.isVisible()) {
      await responsavelTab.click();
      const buscaResponsavel = page.getByPlaceholder(/buscar responsável/i);
      if (await buscaResponsavel.isVisible()) {
        await buscaResponsavel.fill(RESPONSAVEL_COSTA.full_name);
        await page.keyboard.press('Enter');
        const opcao = page.getByRole('option', { name: RESPONSAVEL_COSTA.full_name });
        if (await opcao.isVisible({ timeout: 3_000 })) await opcao.click();
      }
    }

    // ── Salvar ────────────────────────────────────────────────────────
    const botaoSalvar = page.getByRole('button', { name: /salvar|cadastrar|confirmar/i });
    await expect(botaoSalvar).toBeEnabled();
    await botaoSalvar.click();

    // ── Verificar confirmação ──────────────────────────────────────────
    const sucesso = page.getByRole('alert', { name: /sucesso|cadastrado|criado/i })
      .or(page.getByText(/aluno cadastrado com sucesso/i));
    await expect(sucesso).toBeVisible({ timeout: 10_000 });

    // ── Verificar na listagem ──────────────────────────────────────────
    await page.goto('/alunos');
    const buscaGlobal = page.getByPlaceholder(/buscar aluno|pesquisar/i);
    await buscaGlobal.fill('Fernando Oliveira');
    await expect(page.getByText('Fernando Oliveira Souza')).toBeVisible({ timeout: 8_000 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Validações do formulário
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Cadastro de Aluno — Validações', () => {
  test('deve exigir nome completo', async ({ page }) => {
    await navegarParaNovoAluno(page);

    const botaoSalvar = page.getByRole('button', { name: /salvar|cadastrar|próximo/i });
    await botaoSalvar.click();

    // Erro de campo obrigatório
    const nomeInput = page.getByLabel(/nome completo/i);
    await expect(nomeInput).toBeFocused().or(
      expect(page.getByText(/nome é obrigatório|informe o nome/i)).toBeVisible()
    );
  });

  test('deve validar formato do CPF', async ({ page }) => {
    await navegarParaNovoAluno(page);

    await page.getByLabel(/nome completo/i).fill('Aluno Teste');
    const cpfInput = page.getByLabel(/cpf/i);
    await cpfInput.fill('123.456.789-99'); // CPF inválido (dígito verificador errado)
    await cpfInput.blur();

    await expect(page.getByText(/cpf inválido/i)).toBeVisible({ timeout: 3_000 });
  });

  test('deve validar data de nascimento coerente', async ({ page }) => {
    await navegarParaNovoAluno(page);

    const nascimentoInput = page.getByLabel(/data de nascimento|nascimento/i);

    // Data no futuro
    await nascimentoInput.fill('01/01/2030');
    await nascimentoInput.blur();

    await expect(
      page.getByText(/data inválida|data futura|data de nascimento inválida/i)
    ).toBeVisible({ timeout: 3_000 });
  });

  test('deve impedir duplicidade de CPF', async ({ page }) => {
    await navegarParaNovoAluno(page);

    // CPF da Sophia que já existe no sistema
    await page.getByLabel(/nome completo/i).fill('Outro Aluno');
    const cpfInput = page.getByLabel(/cpf/i);
    await cpfInput.fill('111.222.333-44'); // CPF da Sophia Anderson
    await cpfInput.blur();

    await expect(
      page.getByText(/cpf já cadastrado|cpf em uso/i)
    ).toBeVisible({ timeout: 5_000 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Acesso por papel
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Cadastro de Aluno — Controle de acesso', () => {
  test('diretor deve conseguir cadastrar alunos', async ({ page }) => {
    // Re-autenticar como diretor
    await page.goto('/login');
    await page.getByLabel(/e-mail/i).fill('diretor@lexend-test.com.br');
    await page.getByLabel(/senha/i).fill('LexendTest@2025!');
    await page.getByRole('button', { name: /entrar/i }).click();
    await page.waitForURL(/\/dashboard/);

    await page.goto('/alunos');
    const botaoNovo = page.getByRole('button', { name: /novo aluno|adicionar|cadastrar/i });
    await expect(botaoNovo).toBeVisible();
  });
});
