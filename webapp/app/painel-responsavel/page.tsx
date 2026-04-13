'use client';
import { useState, useEffect } from 'react';

type Secao = 'boletim' | 'frequencia' | 'comunicados' | 'cobrancas';

interface Nota {
  id: string;
  subject_name: string;
  grade_value: number;
  assessment_type: string;
  date: string;
}

interface RegistroFrequencia {
  id: string;
  date: string;
  status: 'present' | 'absent' | 'late' | 'excused';
  subject_name?: string;
}

interface Comunicado {
  id: string;
  titulo: string;
  conteudo: string;
  created_at: string;
}

interface Cobranca {
  id: string;
  description: string;
  amount: number;
  due_date: string;
  payment_status: string;
}

interface Filho {
  id: string;
  full_name: string;
  enrollment_code: string;
  grade_name?: string;
  class_name?: string;
}

function fmt(value: number) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
}

const STATUS_FREQ: Record<string, { label: string; color: string }> = {
  present: { label: 'Presente', color: 'text-green-700 bg-green-50' },
  absent:  { label: 'Falta',    color: 'text-red-700 bg-red-50' },
  late:    { label: 'Atraso',   color: 'text-yellow-700 bg-yellow-50' },
  excused: { label: 'Justificado', color: 'text-blue-700 bg-blue-50' },
};

const STATUS_COB: Record<string, { label: string; color: string }> = {
  pending:  { label: 'Pendente',  color: 'text-yellow-700 bg-yellow-50' },
  paid:     { label: 'Pago',      color: 'text-green-700 bg-green-50' },
  failed:   { label: 'Falhou',    color: 'text-red-700 bg-red-50' },
  refunded: { label: 'Estornado', color: 'text-gray-600 bg-gray-100' },
};

// ──────────────────────────────────────────────────────────────
// Seção: Boletim
// ──────────────────────────────────────────────────────────────
function SecaoBoletim({ alunoId }: { alunoId: string }) {
  const [notas, setNotas] = useState<Nota[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/avaliacoes-notas/notas?student_id=${alunoId}`)
      .then(r => r.json())
      .then(d => { setNotas(d.data || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, [alunoId]);

  if (loading) return <p className="text-sm text-gray-500 py-4">Carregando notas...</p>;
  if (notas.length === 0) return <p className="text-sm text-gray-500 py-4">Nenhuma nota registrada.</p>;

  // Agrupa por disciplina
  const porDisciplina: Record<string, Nota[]> = {};
  for (const n of notas) {
    if (!porDisciplina[n.subject_name]) porDisciplina[n.subject_name] = [];
    porDisciplina[n.subject_name].push(n);
  }

  return (
    <div className="space-y-4">
      {Object.entries(porDisciplina).map(([disciplina, ns]) => {
        const media = ns.reduce((acc, n) => acc + n.grade_value, 0) / ns.length;
        return (
          <div key={disciplina} className="bg-white rounded-xl border overflow-hidden">
            <div className="px-4 py-3 flex items-center justify-between bg-gray-50 border-b">
              <span className="font-semibold text-gray-800">{disciplina}</span>
              <span className={`text-sm font-bold ${media >= 5 ? 'text-green-700' : 'text-red-600'}`}>
                Média: {media.toFixed(1)}
              </span>
            </div>
            <table className="w-full text-sm">
              <thead>
                <tr className="text-xs text-gray-500 border-b">
                  <th className="px-4 py-2 text-left font-medium">Avaliação</th>
                  <th className="px-4 py-2 text-right font-medium">Nota</th>
                  <th className="px-4 py-2 text-left font-medium">Data</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {ns.map(n => (
                  <tr key={n.id}>
                    <td className="px-4 py-2 text-gray-700">{n.assessment_type}</td>
                    <td className={`px-4 py-2 text-right font-bold ${n.grade_value >= 5 ? 'text-green-700' : 'text-red-600'}`}>
                      {n.grade_value.toFixed(1)}
                    </td>
                    <td className="px-4 py-2 text-gray-500">{n.date}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        );
      })}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Seção: Frequência
// ──────────────────────────────────────────────────────────────
function SecaoFrequencia({ alunoId }: { alunoId: string }) {
  const [registros, setRegistros] = useState<RegistroFrequencia[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/matriculas-frequencia/frequencia?student_id=${alunoId}&limit=60`)
      .then(r => r.json())
      .then(d => { setRegistros(d.data || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, [alunoId]);

  if (loading) return <p className="text-sm text-gray-500 py-4">Carregando frequência...</p>;
  if (registros.length === 0) return <p className="text-sm text-gray-500 py-4">Nenhum registro de frequência.</p>;

  const total = registros.length;
  const presencas = registros.filter(r => r.status === 'present' || r.status === 'late').length;
  const taxa = total > 0 ? ((presencas / total) * 100).toFixed(1) : '0.0';

  return (
    <div>
      <div className="flex gap-4 mb-4">
        <div className="bg-white rounded-xl border px-5 py-4 flex-1 text-center">
          <p className="text-xs text-gray-500 mb-1">Taxa de presença</p>
          <p className={`text-2xl font-bold ${parseFloat(taxa) >= 75 ? 'text-green-700' : 'text-red-600'}`}>{taxa}%</p>
        </div>
        <div className="bg-white rounded-xl border px-5 py-4 flex-1 text-center">
          <p className="text-xs text-gray-500 mb-1">Presenças</p>
          <p className="text-2xl font-bold text-gray-900">{presencas}/{total}</p>
        </div>
      </div>
      <div className="bg-white rounded-xl border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="px-4 py-3 text-left font-semibold text-gray-600">Data</th>
              <th className="px-4 py-3 text-left font-semibold text-gray-600">Disciplina</th>
              <th className="px-4 py-3 text-left font-semibold text-gray-600">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {registros.map(r => {
              const s = STATUS_FREQ[r.status] || { label: r.status, color: 'text-gray-700 bg-gray-100' };
              return (
                <tr key={r.id}>
                  <td className="px-4 py-2 text-gray-700">{r.date}</td>
                  <td className="px-4 py-2 text-gray-600">{r.subject_name || '—'}</td>
                  <td className="px-4 py-2">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${s.color}`}>{s.label}</span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Seção: Comunicados
// ──────────────────────────────────────────────────────────────
function SecaoComunicados() {
  const [comunicados, setComunicados] = useState<Comunicado[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/comunicados/escola')
      .then(r => r.json())
      .then(d => { setComunicados(d.data || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  if (loading) return <p className="text-sm text-gray-500 py-4">Carregando comunicados...</p>;
  if (comunicados.length === 0)
    return <p className="text-sm text-gray-500 py-4">Nenhum comunicado disponível.</p>;

  return (
    <div className="space-y-3">
      {comunicados.map(c => (
        <div key={c.id} className="bg-white rounded-xl border p-5">
          <div className="flex items-start justify-between gap-3">
            <h3 className="font-semibold text-gray-900">{c.titulo}</h3>
            <span className="text-xs text-gray-400 shrink-0">
              {new Date(c.created_at).toLocaleDateString('pt-BR')}
            </span>
          </div>
          <p className="mt-2 text-sm text-gray-600 leading-relaxed">{c.conteudo}</p>
        </div>
      ))}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Seção: Cobranças em aberto
// ──────────────────────────────────────────────────────────────
function SecaoCobrancas({ alunoId }: { alunoId: string }) {
  const [cobrancas, setCobrancas] = useState<Cobranca[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`/api/financeiro/mensalidades?student_id=${alunoId}&payment_status=pending`)
      .then(r => r.json())
      .then(d => { setCobrancas(d.data || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, [alunoId]);

  if (loading) return <p className="text-sm text-gray-500 py-4">Carregando cobranças...</p>;
  if (cobrancas.length === 0)
    return (
      <div className="bg-green-50 border border-green-200 rounded-xl p-6 text-center">
        <p className="text-green-700 font-semibold">Nenhuma cobrança em aberto.</p>
      </div>
    );

  const total = cobrancas.reduce((acc, c) => acc + c.amount, 0);

  return (
    <div>
      <div className="bg-red-50 border border-red-200 rounded-xl px-5 py-4 mb-4 flex items-center justify-between">
        <p className="text-sm font-medium text-red-700">Total em aberto</p>
        <p className="text-xl font-bold text-red-700">{fmt(total)}</p>
      </div>
      <div className="bg-white rounded-xl border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="px-4 py-3 text-left font-semibold text-gray-600">Descrição</th>
              <th className="px-4 py-3 text-right font-semibold text-gray-600">Valor</th>
              <th className="px-4 py-3 text-left font-semibold text-gray-600">Vencimento</th>
              <th className="px-4 py-3 text-left font-semibold text-gray-600">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {cobrancas.map(c => {
              const s = STATUS_COB[c.payment_status] || { label: c.payment_status, color: 'text-gray-600 bg-gray-100' };
              const vencido = c.payment_status === 'pending' && c.due_date < new Date().toISOString().slice(0, 10);
              return (
                <tr key={c.id}>
                  <td className="px-4 py-3 text-gray-700">{c.description}</td>
                  <td className="px-4 py-3 text-right font-bold text-gray-900">{fmt(c.amount)}</td>
                  <td className={`px-4 py-3 ${vencido ? 'text-red-600 font-medium' : 'text-gray-600'}`}>
                    {c.due_date}
                    {vencido && <span className="ml-1 text-xs">(vencido)</span>}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${s.color}`}>{s.label}</span>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Página principal
// ──────────────────────────────────────────────────────────────
export default function PainelResponsavelPage() {
  const [filhos, setFilhos] = useState<Filho[]>([]);
  const [filhoAtivo, setFilhoAtivo] = useState<Filho | null>(null);
  const [secao, setSecao] = useState<Secao>('boletim');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Busca filhos vinculados via RLS do Supabase (filtra automaticamente pelo guardian logado)
    fetch('/api/alunos?guardians=me')
      .then(r => r.json())
      .then(d => {
        const lista: Filho[] = (d.data || []).map((a: Record<string, unknown>) => ({
          id: a.id as string,
          full_name: a.full_name as string,
          enrollment_code: a.enrollment_code as string,
          grade_name: (a.grades as Record<string, unknown>)?.name as string | undefined,
          class_name: (a.classes as Record<string, unknown>)?.name as string | undefined,
        }));
        setFilhos(lista);
        if (lista.length > 0) setFilhoAtivo(lista[0]);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const secoes: { id: Secao; label: string }[] = [
    { id: 'boletim', label: 'Boletim' },
    { id: 'frequencia', label: 'Frequência' },
    { id: 'comunicados', label: 'Comunicados' },
    { id: 'cobrancas', label: 'Cobranças' },
  ];

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <p className="text-gray-500">Carregando...</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b px-4 sm:px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
            <span className="text-white text-xs font-bold">LS</span>
          </div>
          <h1 className="text-lg font-bold text-gray-900">Portal do Responsável</h1>
        </div>
        <a href="/login" className="text-sm text-gray-500 hover:text-gray-700">Sair</a>
      </header>

      <main className="max-w-3xl mx-auto px-4 sm:px-6 py-6">
        {/* Seletor de filho */}
        {filhos.length > 1 && (
          <div className="mb-5">
            <label className="block text-xs font-medium text-gray-500 mb-1.5">Aluno</label>
            <div className="flex gap-2 flex-wrap">
              {filhos.map(f => (
                <button
                  key={f.id}
                  onClick={() => setFilhoAtivo(f)}
                  className={`px-4 py-2 rounded-full text-sm font-medium border transition-colors ${
                    filhoAtivo?.id === f.id
                      ? 'bg-blue-600 text-white border-blue-600'
                      : 'bg-white text-gray-700 border-gray-200 hover:border-blue-400'
                  }`}
                >
                  {f.full_name}
                </button>
              ))}
            </div>
          </div>
        )}

        {/* Card do filho */}
        {filhoAtivo && (
          <div className="bg-white rounded-xl border px-5 py-4 mb-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-blue-100 flex items-center justify-center shrink-0">
              <span className="text-blue-700 font-bold text-lg">
                {filhoAtivo.full_name.charAt(0).toUpperCase()}
              </span>
            </div>
            <div>
              <p className="font-bold text-gray-900">{filhoAtivo.full_name}</p>
              <p className="text-xs text-gray-500">
                {filhoAtivo.enrollment_code}
                {filhoAtivo.grade_name ? ` · ${filhoAtivo.grade_name}` : ''}
                {filhoAtivo.class_name ? ` · ${filhoAtivo.class_name}` : ''}
              </p>
            </div>
          </div>
        )}

        {/* Navegação por seções */}
        <div className="flex border-b border-gray-200 mb-5 -mx-1 overflow-x-auto">
          {secoes.map(s => (
            <button
              key={s.id}
              onClick={() => setSecao(s.id)}
              className={`px-4 py-2.5 text-sm font-medium whitespace-nowrap border-b-2 transition-colors ${
                secao === s.id
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              {s.label}
            </button>
          ))}
        </div>

        {/* Conteúdo */}
        {filhoAtivo ? (
          <>
            {secao === 'boletim' && <SecaoBoletim alunoId={filhoAtivo.id} />}
            {secao === 'frequencia' && <SecaoFrequencia alunoId={filhoAtivo.id} />}
            {secao === 'comunicados' && <SecaoComunicados />}
            {secao === 'cobrancas' && <SecaoCobrancas alunoId={filhoAtivo.id} />}
          </>
        ) : (
          <div className="bg-white rounded-xl border p-8 text-center text-gray-500">
            Nenhum aluno vinculado a este responsável.
          </div>
        )}
      </main>
    </div>
  );
}
