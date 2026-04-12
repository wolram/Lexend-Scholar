import { chromium, FullConfig } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import { STORAGE_STATE } from './playwright.config';

/**
 * Global setup — Lexend Scholar E2E
 *
 * Autentica cada perfil (diretor, professor, secretário) via Supabase
 * e persiste o estado da sessão em arquivos .auth/*.json para
 * reutilização nos testes sem realizar login repetido.
 */

interface TestCredentials {
  email: string;
  password: string;
  storageStatePath: string;
  expectedRedirect: string;
}

const CREDENTIALS: TestCredentials[] = [
  {
    email: process.env.TEST_DIRETOR_EMAIL ?? 'diretor@lexend-test.com.br',
    password: process.env.TEST_DIRETOR_PASSWORD ?? 'LexendTest@2025!',
    storageStatePath: STORAGE_STATE.diretor,
    expectedRedirect: '/dashboard',
  },
  {
    email: process.env.TEST_PROFESSOR_EMAIL ?? 'professor@lexend-test.com.br',
    password: process.env.TEST_PROFESSOR_PASSWORD ?? 'LexendTest@2025!',
    storageStatePath: STORAGE_STATE.professor,
    expectedRedirect: '/turmas',
  },
  {
    email: process.env.TEST_SECRETARIO_EMAIL ?? 'secretario@lexend-test.com.br',
    password: process.env.TEST_SECRETARIO_PASSWORD ?? 'LexendTest@2025!',
    storageStatePath: STORAGE_STATE.secretario,
    expectedRedirect: '/alunos',
  },
];

async function globalSetup(config: FullConfig) {
  // Garantir que o diretório .auth existe
  const authDir = path.join(__dirname, '.auth');
  if (!fs.existsSync(authDir)) {
    fs.mkdirSync(authDir, { recursive: true });
  }

  const browser = await chromium.launch();
  const baseURL = config.projects[0]?.use.baseURL ?? 'http://localhost:3000';

  for (const cred of CREDENTIALS) {
    console.log(`[global-setup] Autenticando: ${cred.email}`);

    const page = await browser.newPage();

    try {
      await page.goto(`${baseURL}/login`);

      // Preencher formulário de login
      await page.getByLabel('E-mail').fill(cred.email);
      await page.getByLabel('Senha').fill(cred.password);
      await page.getByRole('button', { name: /entrar/i }).click();

      // Aguardar redirecionamento pós-login
      await page.waitForURL(`**${cred.expectedRedirect}`, { timeout: 15_000 });

      // Salvar estado da sessão (cookies + localStorage com token Supabase)
      await page.context().storageState({ path: cred.storageStatePath });
      console.log(`[global-setup] Estado salvo: ${cred.storageStatePath}`);
    } catch (error) {
      console.error(`[global-setup] Falha ao autenticar ${cred.email}:`, error);
      throw error;
    } finally {
      await page.close();
    }
  }

  await browser.close();
}

export default globalSetup;
