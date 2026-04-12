import { test, expect } from '@playwright/test';
import { credenciaisPorPapel } from '../fixtures/escola';

/**
 * LS-64 — E2E: Smoke test de login por todos os perfis
 *
 * Verifica que cada papel (diretor, professor, secretário) consegue:
 *   1. Acessar a página de login
 *   2. Preencher e submeter as credenciais
 *   3. Ser redirecionado para o dashboard correto
 *   4. Ver o menu de navegação adequado ao seu papel
 *   5. Fazer logout com sucesso
 */

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

async function fazerLogin(page: import('@playwright/test').Page, email: string, password: string) {
  await page.goto('/login');
  await expect(page).toHaveURL(/\/login/);

  // Verificar elementos da página de login
  await expect(page.getByRole('heading', { name: /entrar/i })).toBeVisible();

  const emailInput = page.getByLabel(/e-mail/i);
  const senhaInput = page.getByLabel(/senha/i);
  const botaoEntrar = page.getByRole('button', { name: /entrar/i });

  await emailInput.fill(email);
  await senhaInput.fill(password);
  await botaoEntrar.click();
}

async function fazerLogout(page: import('@playwright/test').Page) {
  // Abrir menu do usuário
  const menuUsuario = page.getByRole('button', { name: /menu do usuário|avatar|perfil/i });

  if (await menuUsuario.isVisible()) {
    await menuUsuario.click();
  } else {
    // Fallback: botão de logout direto na sidebar
    await page.getByRole('button', { name: /sair/i }).click();
  }

  await page.getByRole('menuitem', { name: /sair/i }).click();
  await expect(page).toHaveURL(/\/login/);
}

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Perfil Diretor
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Login — Diretor', () => {
  const creds = credenciaisPorPapel('diretor');

  test('deve autenticar e redirecionar para o dashboard', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);

    // Redirecionamento para dashboard do diretor
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10_000 });
    await expect(page.getByRole('heading', { name: /painel|dashboard|visão geral/i })).toBeVisible();
  });

  test('deve exibir o menu completo de administração', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);
    await page.waitForURL(/\/dashboard/);

    // Diretor tem acesso a todos os módulos
    const nav = page.getByRole('navigation');
    await expect(nav.getByRole('link', { name: /alunos/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /turmas|classes/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /professores/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /financeiro|cobranças/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /relatórios/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /configurações/i })).toBeVisible();
  });

  test('deve mostrar o nome do usuário autenticado', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);
    await page.waitForURL(/\/dashboard/);

    // Nome do diretor visível no header
    await expect(page.getByText(/carlos eduardo mendes/i)).toBeVisible({ timeout: 8_000 });
  });

  test('deve fazer logout e retornar para login', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);
    await page.waitForURL(/\/dashboard/);
    await fazerLogout(page);

    // Após logout, tentativa de acessar área protegida deve redirecionar
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/login/);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Perfil Professor
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Login — Professor', () => {
  const creds = credenciaisPorPapel('professor');

  test('deve autenticar e redirecionar para lista de turmas', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);

    await expect(page).toHaveURL(/\/turmas|\/classes/, { timeout: 10_000 });
    await expect(page.getByRole('heading', { name: /minhas turmas|turmas/i })).toBeVisible();
  });

  test('deve exibir apenas módulos do professor', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);
    await page.waitForURL(/\/turmas|\/classes/);

    const nav = page.getByRole('navigation');

    // Módulos acessíveis ao professor
    await expect(nav.getByRole('link', { name: /turmas|minhas turmas/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /frequência/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /notas/i })).toBeVisible();

    // Módulos restritos — não devem aparecer para professor
    await expect(nav.getByRole('link', { name: /financeiro/i })).not.toBeVisible();
    await expect(nav.getByRole('link', { name: /configurações/i })).not.toBeVisible();
  });

  test('deve fazer logout com sucesso', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);
    await page.waitForURL(/\/turmas|\/classes/);
    await fazerLogout(page);
  });

  test('não deve conseguir acessar área administrativa', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);
    await page.waitForURL(/\/turmas|\/classes/);

    // Tentativa de acesso à área de configurações — deve ser bloqueada
    await page.goto('/configuracoes');
    await expect(page).toHaveURL(/\/turmas|\/dashboard|\/403/, { timeout: 5_000 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Perfil Secretário
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Login — Secretário', () => {
  const creds = credenciaisPorPapel('secretario');

  test('deve autenticar e redirecionar para gestão de alunos', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);

    await expect(page).toHaveURL(/\/alunos|\/students/, { timeout: 10_000 });
    await expect(page.getByRole('heading', { name: /alunos|diretório/i })).toBeVisible();
  });

  test('deve exibir módulos da secretaria', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);
    await page.waitForURL(/\/alunos/);

    const nav = page.getByRole('navigation');
    await expect(nav.getByRole('link', { name: /alunos/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /turmas/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /declarações|documentos/i })).toBeVisible();
    await expect(nav.getByRole('link', { name: /matrículas/i })).toBeVisible();
  });

  test('deve fazer logout com sucesso', async ({ page }) => {
    await fazerLogin(page, creds.email, creds.password);
    await page.waitForURL(/\/alunos/);
    await fazerLogout(page);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Cenários de erro
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Login — Erros de autenticação', () => {
  test('deve exibir erro com senha incorreta', async ({ page }) => {
    await page.goto('/login');

    await page.getByLabel(/e-mail/i).fill('diretor@lexend-test.com.br');
    await page.getByLabel(/senha/i).fill('SenhaErrada123!');
    await page.getByRole('button', { name: /entrar/i }).click();

    // Mensagem de erro deve aparecer sem redirecionar
    await expect(page.getByRole('alert')).toBeVisible({ timeout: 8_000 });
    await expect(page).toHaveURL(/\/login/);
  });

  test('deve exibir erro com e-mail inexistente', async ({ page }) => {
    await page.goto('/login');

    await page.getByLabel(/e-mail/i).fill('naoexiste@escola.com.br');
    await page.getByLabel(/senha/i).fill('Qualquer@123!');
    await page.getByRole('button', { name: /entrar/i }).click();

    await expect(page.getByRole('alert')).toBeVisible({ timeout: 8_000 });
    await expect(page).toHaveURL(/\/login/);
  });

  test('deve validar campos obrigatórios antes de submeter', async ({ page }) => {
    await page.goto('/login');

    // Submeter sem preencher nada
    await page.getByRole('button', { name: /entrar/i }).click();

    // Mensagem de validação HTML5 ou custom
    const emailInput = page.getByLabel(/e-mail/i);
    const validationMessage = await emailInput.evaluate(
      (el: HTMLInputElement) => el.validationMessage
    );
    expect(validationMessage).toBeTruthy();
    await expect(page).toHaveURL(/\/login/);
  });

  test('não deve exibir senha em texto claro', async ({ page }) => {
    await page.goto('/login');

    const senhaInput = page.getByLabel(/senha/i);
    await senhaInput.fill('MinhaSenh@123!');

    // O campo deve ser do tipo password
    const tipo = await senhaInput.getAttribute('type');
    expect(tipo).toBe('password');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Testes — Proteção de rotas
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Proteção de rotas — usuário não autenticado', () => {
  test('deve redirecionar /dashboard para /login', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/login/);
  });

  test('deve redirecionar /alunos para /login', async ({ page }) => {
    await page.goto('/alunos');
    await expect(page).toHaveURL(/\/login/);
  });

  test('deve redirecionar /turmas para /login', async ({ page }) => {
    await page.goto('/turmas');
    await expect(page).toHaveURL(/\/login/);
  });

  test('deve redirecionar /configuracoes para /login', async ({ page }) => {
    await page.goto('/configuracoes');
    await expect(page).toHaveURL(/\/login/);
  });
});
