# LS-162 — Load Test para API: 100 Alunos Simultâneos

## Objetivo

Criar e executar script de load test com k6 simulando 100 usuários simultâneos,
medir p95 de latência nos endpoints críticos (frequência, notas, boletim)
e garantir p95 < 500ms sob carga.

---

## Instalação do k6

```bash
# macOS
brew install k6

# Linux (Ubuntu/Debian)
sudo gpg -k
sudo gpg --no-default-keyring \
  --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
  --keyserver hkp://keyserver.ubuntu.com:80 \
  --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6

# Verificar instalação
k6 version
# → k6 v0.55.x (...)
```

---

## Script Principal de Load Test

```javascript
// scripts/qa/load-test-api.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// Métricas customizadas
const frequenciaLatencia = new Trend('frequencia_latencia', true);
const notasLatencia = new Trend('notas_latencia', true);
const boletimLatencia = new Trend('boletim_latencia', true);
const erros = new Rate('taxa_erros');
const totalRequisicoes = new Counter('total_requisicoes');

// Configuração do cenário
export const options = {
  scenarios: {
    // Cenário 1: Ramp-up gradual até 100 usuários
    ramp_up: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 25 },   // Subir para 25 usuários em 30s
        { duration: '30s', target: 50 },   // Subir para 50 usuários em 30s
        { duration: '30s', target: 100 },  // Subir para 100 usuários em 30s
        { duration: '2m', target: 100 },   // Manter 100 usuários por 2 minutos
        { duration: '30s', target: 0 },    // Descer para 0
      ],
    },
  },
  
  // Thresholds que definem sucesso/falha
  thresholds: {
    // p95 deve ser < 500ms em todos os endpoints
    'http_req_duration{endpoint:frequencia}': ['p(95)<500'],
    'http_req_duration{endpoint:notas}': ['p(95)<500'],
    'http_req_duration{endpoint:boletim}': ['p(95)<500'],
    'http_req_duration{endpoint:alunos}': ['p(95)<800'],
    
    // Taxa de erro deve ser < 1%
    'http_req_failed': ['rate<0.01'],
    'taxa_erros': ['rate<0.01'],
    
    // p99 deve ser < 1000ms
    'http_req_duration': ['p(99)<1000'],
  },
};

// Dados de teste
const BASE_URL = __ENV.API_URL || 'https://api.lexendscholar.com.br';
const TEST_ESCOLA_ID = __ENV.ESCOLA_ID || 'escola-teste-load';

// Login e obter token
function autenticar(usuarioIndex) {
  const email = `professor${usuarioIndex % 10}@escola-teste.com`;
  
  const loginRes = http.post(
    `${BASE_URL}/auth/login`,
    JSON.stringify({
      email: email,
      senha: 'Senha@Teste2026',
      escolaId: TEST_ESCOLA_ID,
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { endpoint: 'auth' },
    }
  );
  
  check(loginRes, {
    'login retornou 200': (r) => r.status === 200,
    'token presente': (r) => r.json('token') !== undefined,
  });
  
  return loginRes.json('token');
}

// Cenário principal executado por cada VU (Virtual User)
export default function () {
  const vuId = __VU;
  const token = autenticar(vuId);
  
  if (!token) {
    erros.add(1);
    return;
  }
  
  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  };
  
  const turmaId = `turma-${(vuId % 20) + 1}`; // 20 turmas diferentes
  const dataHoje = new Date().toISOString().split('T')[0];
  
  // --- ENDPOINT 1: Listar Alunos da Turma ---
  const alunosRes = http.get(
    `${BASE_URL}/turmas/${turmaId}/alunos`,
    { headers, tags: { endpoint: 'alunos' } }
  );
  
  check(alunosRes, {
    'alunos: status 200': (r) => r.status === 200,
    'alunos: lista retornada': (r) => Array.isArray(r.json()),
  });
  erros.add(alunosRes.status !== 200);
  totalRequisicoes.add(1);
  
  sleep(0.5);
  
  // --- ENDPOINT 2: Registrar Frequência ---
  const alunos = alunosRes.json() || [];
  const chamadaPayload = {
    turmaId: turmaId,
    data: dataHoje,
    registros: alunos.slice(0, 30).map((a, i) => ({
      alunoId: a.id,
      presente: i % 5 !== 0, // 80% de presença simulada
    })),
  };
  
  const frequenciaRes = http.post(
    `${BASE_URL}/frequencia/registrar`,
    JSON.stringify(chamadaPayload),
    { headers, tags: { endpoint: 'frequencia' } }
  );
  
  frequenciaLatencia.add(frequenciaRes.timings.duration);
  
  check(frequenciaRes, {
    'frequencia: status 200 ou 201': (r) => [200, 201].includes(r.status),
    'frequencia: id retornado': (r) => r.json('id') !== undefined,
  });
  erros.add(![200, 201].includes(frequenciaRes.status));
  totalRequisicoes.add(1);
  
  sleep(0.5);
  
  // --- ENDPOINT 3: Lançar Notas ---
  const notasPayload = {
    turmaId: turmaId,
    disciplinaId: `disc-${(vuId % 8) + 1}`,
    bimestre: 1,
    notas: alunos.slice(0, 30).map(a => ({
      alunoId: a.id,
      valor: Math.round(Math.random() * 100) / 10, // Nota 0.0 a 10.0
    })),
  };
  
  const notasRes = http.post(
    `${BASE_URL}/notas/lancar`,
    JSON.stringify(notasPayload),
    { headers, tags: { endpoint: 'notas' } }
  );
  
  notasLatencia.add(notasRes.timings.duration);
  
  check(notasRes, {
    'notas: status 200 ou 201': (r) => [200, 201].includes(r.status),
  });
  erros.add(![200, 201].includes(notasRes.status));
  totalRequisicoes.add(1);
  
  sleep(1);
  
  // --- ENDPOINT 4: Gerar Boletim (endpoint mais pesado) ---
  const alunoId = alunos[0]?.id || 'aluno-default';
  
  const boletimRes = http.get(
    `${BASE_URL}/boletim/${alunoId}?bimestre=1`,
    { headers, tags: { endpoint: 'boletim' } }
  );
  
  boletimLatencia.add(boletimRes.timings.duration);
  
  check(boletimRes, {
    'boletim: status 200': (r) => r.status === 200,
    'boletim: dados de notas presentes': (r) => r.json('notas') !== undefined,
  });
  erros.add(boletimRes.status !== 200);
  totalRequisicoes.add(1);
  
  sleep(2); // Pausa entre iterações
}

// Relatório final
export function handleSummary(data) {
  const summary = {
    timestamp: new Date().toISOString(),
    resultado: data.metrics.http_req_failed.values.rate < 0.01 ? 'PASSOU' : 'FALHOU',
    metricas: {
      requisicoes_totais: data.metrics.total_requisicoes?.values.count || 0,
      taxa_erro: `${(data.metrics.http_req_failed.values.rate * 100).toFixed(2)}%`,
      latencia_p50: `${data.metrics.http_req_duration.values['p(50)'].toFixed(0)}ms`,
      latencia_p95: `${data.metrics.http_req_duration.values['p(95)'].toFixed(0)}ms`,
      latencia_p99: `${data.metrics.http_req_duration.values['p(99)'].toFixed(0)}ms`,
      frequencia_p95: `${data.metrics.frequencia_latencia?.values['p(95)']?.toFixed(0) || '?'}ms`,
      notas_p95: `${data.metrics.notas_latencia?.values['p(95)']?.toFixed(0) || '?'}ms`,
      boletim_p95: `${data.metrics.boletim_latencia?.values['p(95)']?.toFixed(0) || '?'}ms`,
    },
  };
  
  return {
    'docs/quality/load-test-results.json': JSON.stringify(summary, null, 2),
    stdout: `
============================================================
RESULTADO DO LOAD TEST — LEXEND SCHOLAR API
============================================================
Status: ${summary.resultado}
Total de requisições: ${summary.metricas.requisicoes_totais}
Taxa de erro: ${summary.metricas.taxa_erro} (meta: < 1%)

Latência Geral:
  p50: ${summary.metricas.latencia_p50}
  p95: ${summary.metricas.latencia_p95} (meta: < 500ms)
  p99: ${summary.metricas.latencia_p99}

Por Endpoint (p95):
  /frequencia/registrar: ${summary.metricas.frequencia_p95} (meta: < 500ms)
  /notas/lancar:         ${summary.metricas.notas_p95} (meta: < 500ms)
  /boletim/:id:          ${summary.metricas.boletim_p95} (meta: < 500ms)
============================================================
`,
  };
}
```

---

## Como Executar

```bash
# Teste local (contra ambiente de staging)
API_URL=https://api-staging.lexendscholar.com.br \
ESCOLA_ID=escola-qa-load-test \
k6 run scripts/qa/load-test-api.js

# Teste com output para InfluxDB (monitoramento contínuo)
k6 run \
  --out influxdb=http://localhost:8086/k6 \
  scripts/qa/load-test-api.js

# Smoke test rápido (apenas 1 usuário, 30 segundos)
k6 run --vus 1 --duration 30s scripts/qa/load-test-api.js

# Stress test (além da capacidade planejada)
k6 run \
  --vus 200 \
  --duration 1m \
  scripts/qa/load-test-api.js
```

---

## Resultados Esperados (Metas)

| Endpoint | p50 | p95 | p99 | Taxa de Erro |
|----------|-----|-----|-----|-------------|
| `GET /alunos` | ≤ 100ms | ≤ 300ms | ≤ 500ms | < 1% |
| `POST /frequencia/registrar` | ≤ 150ms | ≤ 500ms | ≤ 800ms | < 1% |
| `POST /notas/lancar` | ≤ 150ms | ≤ 500ms | ≤ 800ms | < 1% |
| `GET /boletim/:id` | ≤ 200ms | ≤ 500ms | ≤ 1000ms | < 1% |

---

## Pré-requisitos do Ambiente de Teste

```sql
-- Dados de seed necessários no banco de dados de staging:
-- 1. Escola de teste criada:
INSERT INTO escolas (id, nome) VALUES ('escola-qa-load-test', 'Escola QA Load Test');

-- 2. 100 professores de teste (professor0 a professor99):
-- (executar via script de seed)

-- 3. 20 turmas com 30 alunos cada (= 600 alunos total):
-- (executar via script de seed)

-- 4. 8 disciplinas configuradas
```

```bash
# Executar seed de dados para load test
node scripts/qa/seed-load-test-data.js \
  --escola escola-qa-load-test \
  --professores 10 \
  --turmas 20 \
  --alunos-por-turma 30
```

---

## Integração no CI

```yaml
# .github/workflows/load-test.yml
name: Load Test API

on:
  schedule:
    - cron: '0 3 * * 0'  # Domingo às 3h UTC
  workflow_dispatch:
    inputs:
      vus:
        description: 'Número de usuários virtuais'
        default: '100'

jobs:
  load-test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install k6
        run: |
          sudo gpg --no-default-keyring \
            --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
            --keyserver hkp://keyserver.ubuntu.com:80 \
            --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] \
            https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update && sudo apt-get install -y k6
      
      - name: Run Load Test
        env:
          API_URL: ${{ secrets.STAGING_API_URL }}
          ESCOLA_ID: escola-qa-load-test
        run: |
          k6 run \
            --vus ${{ github.event.inputs.vus || '100' }} \
            scripts/qa/load-test-api.js
      
      - name: Upload Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: load-test-results
          path: docs/quality/load-test-results.json
```

---

## Referências

- [k6 Documentation](https://grafana.com/docs/k6/latest/)
- [k6 Scenarios](https://grafana.com/docs/k6/latest/using-k6/scenarios/)
- [Grafana k6 Thresholds](https://grafana.com/docs/k6/latest/using-k6/thresholds/)
- [Release Criteria — LS-166](./LS-166-release-criteria.md)
- [Performance Monitoring — LS-164](./LS-164-monitoring-performance-ci.md)
