/**
 * LS-162 — Load Test API: 100 alunos simultâneos
 * Ferramenta: k6 (https://grafana.com/docs/k6/latest/)
 *
 * Uso:
 *   k6 run scripts/qa/load-test-api.js
 *   API_URL=https://api-staging.lexendscholar.com.br k6 run scripts/qa/load-test-api.js
 *
 * Instalar k6:
 *   macOS: brew install k6
 *   Linux: ver docs/quality/LS-162-load-test-api.md
 */

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Métricas customizadas por endpoint
const frequenciaLatencia = new Trend('frequencia_latencia', true);
const notasLatencia = new Trend('notas_latencia', true);
const boletimLatencia = new Trend('boletim_latencia', true);
const erros = new Rate('taxa_erros');
const totalRequisicoes = new Counter('total_requisicoes');

// Configuração de cenários e thresholds
export const options = {
  scenarios: {
    carga_progressiva: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 25 },
        { duration: '30s', target: 50 },
        { duration: '30s', target: 100 },
        { duration: '2m', target: 100 },
        { duration: '30s', target: 0 },
      ],
    },
  },
  thresholds: {
    // p95 < 500ms em endpoints críticos
    'http_req_duration{endpoint:frequencia}': ['p(95)<500'],
    'http_req_duration{endpoint:notas}': ['p(95)<500'],
    'http_req_duration{endpoint:boletim}': ['p(95)<500'],
    'http_req_duration{endpoint:alunos}': ['p(95)<800'],
    // Taxa de erro < 1%
    'http_req_failed': ['rate<0.01'],
    'taxa_erros': ['rate<0.01'],
    // p99 < 1000ms
    'http_req_duration': ['p(99)<1000'],
  },
};

const BASE_URL = __ENV.API_URL || 'https://api-staging.lexendscholar.com.br';
const TEST_ESCOLA_ID = __ENV.ESCOLA_ID || 'escola-qa-load-test';

function autenticar(vuId) {
  const email = `professor${vuId % 10}@escola-teste.com`;

  const res = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      email,
      senha: 'Senha@Teste2026',
      escolaId: TEST_ESCOLA_ID,
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { endpoint: 'auth' },
    }
  );

  check(res, {
    'login: status 200': (r) => r.status === 200,
    'login: token presente': (r) => r.json('token') !== undefined,
  });

  return res.json('token');
}

export default function () {
  const vuId = __VU;
  const token = autenticar(vuId);

  if (!token) {
    erros.add(1);
    return;
  }

  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  };

  const turmaId = `turma-${(vuId % 20) + 1}`;
  const dataHoje = new Date().toISOString().split('T')[0];

  // GET /turmas/:id/alunos
  const alunosRes = http.get(`${BASE_URL}/turmas/${turmaId}/alunos`, {
    headers,
    tags: { endpoint: 'alunos' },
  });

  check(alunosRes, {
    'alunos: status 200': (r) => r.status === 200,
    'alunos: array retornado': (r) => Array.isArray(r.json()),
  });
  erros.add(alunosRes.status !== 200);
  totalRequisicoes.add(1);

  sleep(0.5);

  // POST /frequencia/registrar
  const alunos = alunosRes.json() || [];
  const chamadaPayload = {
    turmaId,
    data: dataHoje,
    registros: alunos.slice(0, 30).map((a, i) => ({
      alunoId: a.id || `aluno-${i}`,
      presente: i % 5 !== 0,
    })),
  };

  const frequenciaRes = http.post(
    `${BASE_URL}/frequencia/registrar`,
    JSON.stringify(chamadaPayload),
    { headers, tags: { endpoint: 'frequencia' } }
  );

  frequenciaLatencia.add(frequenciaRes.timings.duration);
  check(frequenciaRes, {
    'frequencia: status 200/201': (r) => [200, 201].includes(r.status),
  });
  erros.add(![200, 201].includes(frequenciaRes.status));
  totalRequisicoes.add(1);

  sleep(0.5);

  // POST /notas/lancar
  const notasPayload = {
    turmaId,
    disciplinaId: `disc-${(vuId % 8) + 1}`,
    bimestre: 1,
    notas: alunos.slice(0, 30).map((a, i) => ({
      alunoId: a.id || `aluno-${i}`,
      valor: Math.round(Math.random() * 100) / 10,
    })),
  };

  const notasRes = http.post(
    `${BASE_URL}/notas/lancar`,
    JSON.stringify(notasPayload),
    { headers, tags: { endpoint: 'notas' } }
  );

  notasLatencia.add(notasRes.timings.duration);
  check(notasRes, {
    'notas: status 200/201': (r) => [200, 201].includes(r.status),
  });
  erros.add(![200, 201].includes(notasRes.status));
  totalRequisicoes.add(1);

  sleep(1);

  // GET /boletim/:alunoId
  const alunoId = alunos[0]?.id || 'aluno-default';
  const boletimRes = http.get(
    `${BASE_URL}/boletim/${alunoId}?bimestre=1`,
    { headers, tags: { endpoint: 'boletim' } }
  );

  boletimLatencia.add(boletimRes.timings.duration);
  check(boletimRes, {
    'boletim: status 200': (r) => r.status === 200,
    'boletim: notas presentes': (r) => r.json('notas') !== undefined,
  });
  erros.add(boletimRes.status !== 200);
  totalRequisicoes.add(1);

  sleep(2);
}

export function handleSummary(data) {
  const m = data.metrics;

  const p95Geral = m.http_req_duration?.values['p(95)']?.toFixed(0) || '?';
  const p95Freq = m.frequencia_latencia?.values['p(95)']?.toFixed(0) || '?';
  const p95Notas = m.notas_latencia?.values['p(95)']?.toFixed(0) || '?';
  const p95Boletim = m.boletim_latencia?.values['p(95)']?.toFixed(0) || '?';
  const taxaErro = ((m.http_req_failed?.values?.rate || 0) * 100).toFixed(2);
  const totalReqs = m.total_requisicoes?.values?.count || 0;

  const metaAtingida =
    parseFloat(p95Freq) < 500 &&
    parseFloat(p95Notas) < 500 &&
    parseFloat(p95Boletim) < 500 &&
    parseFloat(taxaErro) < 1.0;

  const resultado = metaAtingida ? 'PASSOU' : 'FALHOU';

  const resumo = {
    timestamp: new Date().toISOString(),
    resultado,
    total_requisicoes: totalReqs,
    taxa_erro_pct: parseFloat(taxaErro),
    latencia_p95_ms: parseFloat(p95Geral),
    por_endpoint: {
      frequencia_p95_ms: parseFloat(p95Freq),
      notas_p95_ms: parseFloat(p95Notas),
      boletim_p95_ms: parseFloat(p95Boletim),
    },
  };

  return {
    'docs/quality/load-test-results.json': JSON.stringify(resumo, null, 2),
    stdout: `
==============================================================
RESULTADO DO LOAD TEST — LEXEND SCHOLAR API
==============================================================
Status:              ${resultado}
Total de requisições: ${totalReqs}
Taxa de erro:        ${taxaErro}% (meta: < 1%)

Latência p95 Geral:  ${p95Geral}ms

Por Endpoint (p95):
  /frequencia/registrar: ${p95Freq}ms  (meta: < 500ms)
  /notas/lancar:         ${p95Notas}ms  (meta: < 500ms)
  /boletim/:id:          ${p95Boletim}ms  (meta: < 500ms)
==============================================================
`,
  };
}
