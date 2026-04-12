import { defineConfig, devices } from '@playwright/test';
import path from 'path';

/**
 * Playwright E2E configuration — Lexend Scholar
 *
 * Cobre o website público (marketing) e o web app (painel escolar).
 * Autenticação via Supabase com perfis: diretor, professor, secretário.
 *
 * Documentação: docs/testing/playwright-setup.md
 */

// URL base para cada ambiente
const BASE_URL = process.env.BASE_URL ?? 'http://localhost:3000';
const WEBSITE_URL = process.env.WEBSITE_URL ?? 'http://localhost:4000';

// Arquivo de estado de autenticação por perfil (gerado por global-setup)
export const STORAGE_STATE = {
  diretor: path.join(__dirname, '.auth/diretor.json'),
  professor: path.join(__dirname, '.auth/professor.json'),
  secretario: path.join(__dirname, '.auth/secretario.json'),
};

export default defineConfig({
  testDir: '.',
  outputDir: '../../test-results',

  // Timeout global por teste (ms)
  timeout: 30_000,

  // Timeout para expect/assertions
  expect: {
    timeout: 8_000,
  },

  // Continuar rodando outros testes mesmo se um falhar
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 2 : undefined,

  // Relatórios
  reporter: [
    ['list'],
    ['html', { outputFolder: '../../playwright-report', open: 'never' }],
    ['junit', { outputFile: '../../test-results/junit.xml' }],
    ...(process.env.CI ? [['github'] as [string]] : []),
  ],

  // Setup global: cria sessões autenticadas para cada perfil
  globalSetup: require.resolve('./global-setup'),

  // Configurações compartilhadas por todos os projetos
  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
    locale: 'pt-BR',
    timezoneId: 'America/Sao_Paulo',

    // Headers padrão
    extraHTTPHeaders: {
      'x-lexend-test': 'true',
    },
  },

  projects: [
    // ─────────────────────────────────────────────────────────────
    // Projeto: autenticação (sem estado salvo — gera os arquivos .auth)
    // ─────────────────────────────────────────────────────────────
    {
      name: 'setup-auth',
      testMatch: /global-setup\.ts/,
      use: { ...devices['Desktop Chrome'] },
    },

    // ─────────────────────────────────────────────────────────────
    // Projeto: website público (sem autenticação)
    // ─────────────────────────────────────────────────────────────
    {
      name: 'website-chrome',
      testMatch: /website\/.+\.spec\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        baseURL: WEBSITE_URL,
      },
    },
    {
      name: 'website-mobile',
      testMatch: /website\/.+\.spec\.ts/,
      use: {
        ...devices['iPhone 14'],
        baseURL: WEBSITE_URL,
      },
    },

    // ─────────────────────────────────────────────────────────────
    // Projeto: web app — perfil Diretor
    // ─────────────────────────────────────────────────────────────
    {
      name: 'app-diretor',
      testMatch: /(?<!website\/).+\.spec\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        baseURL: BASE_URL,
        storageState: STORAGE_STATE.diretor,
      },
      dependencies: ['setup-auth'],
    },

    // ─────────────────────────────────────────────────────────────
    // Projeto: web app — perfil Professor
    // ─────────────────────────────────────────────────────────────
    {
      name: 'app-professor',
      testMatch: /(?<!website\/).+\.spec\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        baseURL: BASE_URL,
        storageState: STORAGE_STATE.professor,
      },
      dependencies: ['setup-auth'],
    },

    // ─────────────────────────────────────────────────────────────
    // Projeto: web app — perfil Secretário
    // ─────────────────────────────────────────────────────────────
    {
      name: 'app-secretario',
      testMatch: /(?<!website\/).+\.spec\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        baseURL: BASE_URL,
        storageState: STORAGE_STATE.secretario,
      },
      dependencies: ['setup-auth'],
    },

    // ─────────────────────────────────────────────────────────────
    // Projeto: smoke tests (todos os perfis, Chrome + Firefox)
    // ─────────────────────────────────────────────────────────────
    {
      name: 'smoke-firefox',
      testMatch: /login\.spec\.ts/,
      use: {
        ...devices['Desktop Firefox'],
        baseURL: BASE_URL,
      },
    },
  ],

  // Servidor local de desenvolvimento (opcional — remova se usar URL remota)
  webServer: process.env.CI
    ? undefined
    : {
        command: 'npm run dev',
        url: BASE_URL,
        reuseExistingServer: true,
        timeout: 60_000,
        cwd: path.join(__dirname, '../../webapp'),
      },
});
