import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 25 },    // Ramp up para 25 usuários em 30s
    { duration: '60s', target: 100 },   // Ramp up para 100 usuários em 60s
    { duration: '120s', target: 100 },  // Manter 100 usuários por 2 minutos
    { duration: '30s', target: 0 },     // Ramp down para 0
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],   // 95% das requests em menos de 500ms
    http_req_failed: ['rate<0.01'],     // Menos de 1% de falhas
  },
};

const BASE_URL = __ENV.API_URL || 'http://localhost:3000';

export default function () {
  // ── 1. Login ──────────────────────────────────────────────────
  const loginRes = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      email: `test+${__VU}@escola.com`,
      password: 'test123',
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );

  check(loginRes, {
    'login status 200': (r) => r.status === 200,
    'login retorna token': (r) => r.json('access_token') !== undefined,
  });

  if (loginRes.status !== 200) {
    console.error(`VU ${__VU}: login falhou com status ${loginRes.status}`);
    return;
  }

  const token = loginRes.json('access_token');
  const headers = {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  };

  sleep(0.5);

  // ── 2. Listar alunos da turma ─────────────────────────────────
  const studentsRes = http.get(
    `${BASE_URL}/students?class_id=1&page=1&limit=50`,
    { headers }
  );

  check(studentsRes, {
    'students status 200': (r) => r.status === 200,
    'students retorna array': (r) => Array.isArray(r.json('data')),
  });

  sleep(0.5);

  // ── 3. Registrar frequência ───────────────────────────────────
  const today = new Date().toISOString().split('T')[0];
  const attendanceRes = http.post(
    `${BASE_URL}/attendance`,
    JSON.stringify({
      student_id: __VU,
      class_id: 1,
      status: 'present',
      date: today,
    }),
    { headers }
  );

  check(attendanceRes, {
    'attendance status 201': (r) => r.status === 201,
    'attendance sem erro': (r) => r.json('error') === undefined,
  });

  sleep(0.5);

  // ── 4. Relatório de frequência ────────────────────────────────
  const reportRes = http.get(
    `${BASE_URL}/reports/attendance?class_id=1&start_date=${today}&end_date=${today}`,
    { headers }
  );

  check(reportRes, {
    'report status 200': (r) => r.status === 200,
    'report tempo < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1);

  // ── 5. Listar cobranças ───────────────────────────────────────
  const billingsRes = http.get(
    `${BASE_URL}/billings?status=pending&page=1`,
    { headers }
  );

  check(billingsRes, {
    'billings status 200': (r) => r.status === 200,
  });

  sleep(1);
}

// ── Handlers de ciclo de vida ──────────────────────────────────────

export function setup() {
  console.log(`Iniciando load test contra: ${BASE_URL}`);
  console.log('Stages: ramp 25 (30s) → ramp 100 (60s) → hold 100 (120s) → ramp 0 (30s)');

  // Verificar que a API está respondendo
  const healthRes = http.get(`${BASE_URL}/health`);
  if (healthRes.status !== 200) {
    throw new Error(`API não está respondendo em ${BASE_URL}/health — status: ${healthRes.status}`);
  }
  console.log('Health check: OK');
}

export function teardown(data) {
  console.log('Load test concluído.');
  console.log('Verificar thresholds: p95 < 500ms e error rate < 1%');
}
