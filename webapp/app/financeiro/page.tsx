'use client';
import { useState, useEffect, useCallback } from 'react';

type StatusPagamento = 'pending' | 'paid' | 'failed' | 'refunded';
type Aba = 'cobrancas' | 'inadimplencia' | 'relatorio';

interface Mensalidade {
  id: string;
  description: string;
  amount: number;
  due_date: string;
  paid_date?: string;
  payment_status: StatusPagamento;
  payment_method?: string;
  notes?: string;
  students?: { id: string; full_name: string; enrollment_code: string };
}

interface AlunoInadimplente {
  student: { id: string; full_name: string; enrollment_code: string; email?: string; phone?: string };
  total_overdue: number;
  records: { id: string; description: string; amount: number; due_date: string; days_overdue?: number }[];
}

interface Resumo {
  total: number;
  pending: number;
  paid: number;
  failed: number;
  overdue: number;
  overdue_count: number;
  total_records: number;
}

const STATUS_LABELS: Record<StatusPagamento, string> = {
  pending: 'Pendente',
  paid: 'Pago',
  failed: 'Falhou',
  refunded: 'Estornado',
};

const STATUS_COLORS: Record<StatusPagamento, string> = {
  pending: 'bg-yellow-100 text-yellow-800',
  paid: 'bg-green-100 text-green-800',
  failed: 'bg-red-100 text-red-800',
  refunded: 'bg-gray-100 text-gray-700',
};

function fmt(value: number) {
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);
}

function getMesAtual() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
}

// ──────────────────────────────────────────────────────────────
// Modal de pagamento
// ──────────────────────────────────────────────────────────────
function ModalPagamento({
  cobranca,
  onClose,
  onSaved,
}: {
  cobranca: Mensalidade;
  onClose: () => void;
  onSaved: () => void;
}) {
  const [status, setStatus] = useState<StatusPagamento>(cobranca.payment_status);
  const [metodo, setMetodo] = useState(cobranca.payment_method || '');
  const [notas, setNotas] = useState(cobranca.notes || '');
  const [saving, setSaving] = useState(false);
  const [erro, setErro] = useState('');

  async function salvar() {
    setSaving(true);
    setErro('');
    try {
      const res = await fetch(`/api/financeiro/mensalidades/${cobranca.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ payment_status: status, payment_method: metodo || undefined, notes: notas || undefined }),
      });
      if (!res.ok) throw new Error('Erro ao salvar');
      onSaved();
      onClose();
    } catch {
      setErro('Falha ao registrar pagamento. Tente novamente.');
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40" onClick={onClose}>
      <div className="bg-white rounded-xl shadow-xl w-full max-w-md mx-4 p-6" onClick={e => e.stopPropagation()}>
        <h3 className="text-lg font-bold text-gray-900 mb-1">Registrar Pagamento</h3>
        <p className="text-sm text-gray-500 mb-4">
          {cobranca.students?.full_name} — {cobranca.description} — {fmt(cobranca.amount)}
        </p>
        {erro && <p className="text-sm text-red-600 mb-3">{erro}</p>}
        <div className="space-y-3">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
            <select
              value={status}
              onChange={e => setStatus(e.target.value as StatusPagamento)}
              className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {(Object.keys(STATUS_LABELS) as StatusPagamento[]).map(s => (
                <option key={s} value={s}>{STATUS_LABELS[s]}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Método de pagamento</label>
            <input
              type="text"
              value={metodo}
              onChange={e => setMetodo(e.target.value)}
              placeholder="PIX, boleto, cartão..."
              className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Observações</label>
            <textarea
              value={notas}
              onChange={e => setNotas(e.target.value)}
              rows={2}
              className="w-full border rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>
        <div className="flex gap-3 mt-5">
          <button
            onClick={onClose}
            className="flex-1 border rounded-lg px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50"
          >
            Cancelar
          </button>
          <button
            onClick={salvar}
            disabled={saving}
            className="flex-1 bg-blue-600 text-white rounded-lg px-4 py-2 text-sm font-semibold hover:bg-blue-700 disabled:opacity-60"
          >
            {saving ? 'Salvando...' : 'Salvar'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Aba: Cobranças
// ──────────────────────────────────────────────────────────────
function AbaCobrancas() {
  const [lista, setLista] = useState<Mensalidade[]>([]);
  const [loading, setLoading] = useState(true);
  const [filtroStatus, setFiltroStatus] = useState<string>('');
  const [gerando, setGerando] = useState(false);
  const [cobrancaSelecionada, setCobrancaSelecionada] = useState<Mensalidade | null>(null);

  const carregar = useCallback(async () => {
    setLoading(true);
    const qs = filtroStatus ? `?payment_status=${filtroStatus}` : '';
    const res = await fetch(`/api/financeiro/mensalidades${qs}`);
    const data = await res.json();
    setLista(data.data || []);
    setLoading(false);
  }, [filtroStatus]);

  useEffect(() => { carregar(); }, [carregar]);

  async function gerarCobrancasMes() {
    const mes = getMesAtual();
    const descricao = prompt(`Descrição da cobrança (ex: Mensalidade ${mes}):`, `Mensalidade ${mes}`);
    if (!descricao) return;
    const valorStr = prompt('Valor (R$):', '');
    if (!valorStr) return;
    const valor = parseFloat(valorStr.replace(',', '.'));
    if (isNaN(valor) || valor <= 0) { alert('Valor inválido.'); return; }
    const vencimento = prompt('Data de vencimento (AAAA-MM-DD):', `${mes}-10`);
    if (!vencimento) return;
    setGerando(true);
    try {
      const res = await fetch('/api/financeiro/mensalidades/gerar-lote', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ description: descricao, amount: valor, due_date: vencimento }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Erro');
      alert(`${data.inserted} cobranças geradas com sucesso!`);
      carregar();
    } catch (e: unknown) {
      alert(`Erro ao gerar cobranças: ${e instanceof Error ? e.message : 'desconhecido'}`);
    } finally {
      setGerando(false);
    }
  }

  return (
    <>
      {cobrancaSelecionada && (
        <ModalPagamento
          cobranca={cobrancaSelecionada}
          onClose={() => setCobrancaSelecionada(null)}
          onSaved={carregar}
        />
      )}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <label className="text-sm font-medium text-gray-700">Filtrar por status:</label>
          <select
            value={filtroStatus}
            onChange={e => setFiltroStatus(e.target.value)}
            className="border rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="">Todos</option>
            {(Object.keys(STATUS_LABELS) as StatusPagamento[]).map(s => (
              <option key={s} value={s}>{STATUS_LABELS[s]}</option>
            ))}
          </select>
        </div>
        <button
          onClick={gerarCobrancasMes}
          disabled={gerando}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-blue-700 disabled:opacity-60"
        >
          {gerando ? 'Gerando...' : 'Gerar cobranças do mês'}
        </button>
      </div>
      <div className="bg-white rounded-xl border overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Carregando...</div>
        ) : lista.length === 0 ? (
          <div className="p-8 text-center text-gray-500">Nenhuma cobrança encontrada.</div>
        ) : (
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-4 py-3 text-left font-semibold text-gray-600">Aluno</th>
                <th className="px-4 py-3 text-left font-semibold text-gray-600">Descrição</th>
                <th className="px-4 py-3 text-right font-semibold text-gray-600">Valor</th>
                <th className="px-4 py-3 text-left font-semibold text-gray-600">Vencimento</th>
                <th className="px-4 py-3 text-left font-semibold text-gray-600">Status</th>
                <th className="px-4 py-3 text-left font-semibold text-gray-600">Ações</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {lista.map(m => (
                <tr key={m.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-900">{m.students?.full_name || '—'}</td>
                  <td className="px-4 py-3 text-gray-600">{m.description}</td>
                  <td className="px-4 py-3 text-right font-medium text-gray-900">{fmt(m.amount)}</td>
                  <td className="px-4 py-3 text-gray-600">{m.due_date}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${STATUS_COLORS[m.payment_status]}`}>
                      {STATUS_LABELS[m.payment_status]}
                    </span>
                  </td>
                  <td className="px-4 py-3">
                    <button
                      onClick={() => setCobrancaSelecionada(m)}
                      className="text-blue-600 hover:text-blue-700 text-xs font-medium"
                    >
                      Registrar pagamento
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </>
  );
}

// ──────────────────────────────────────────────────────────────
// Aba: Inadimplência
// ──────────────────────────────────────────────────────────────
function AbaInadimplencia() {
  const [lista, setLista] = useState<AlunoInadimplente[]>([]);
  const [loading, setLoading] = useState(true);
  const [expandido, setExpandido] = useState<string | null>(null);

  useEffect(() => {
    fetch('/api/financeiro/inadimplentes')
      .then(r => r.json())
      .then(d => { setLista(d.data || []); setLoading(false); })
      .catch(() => setLoading(false));
  }, []);

  if (loading) return <div className="p-8 text-center text-gray-500">Carregando...</div>;
  if (lista.length === 0)
    return <div className="bg-white rounded-xl border p-8 text-center text-gray-500">Nenhum aluno inadimplente.</div>;

  return (
    <div className="space-y-3">
      {lista.map(item => (
        <div key={item.student.id} className="bg-white rounded-xl border overflow-hidden">
          <button
            className="w-full px-5 py-4 flex items-center justify-between hover:bg-gray-50 text-left"
            onClick={() => setExpandido(expandido === item.student.id ? null : item.student.id)}
          >
            <div>
              <p className="font-semibold text-gray-900">{item.student.full_name}</p>
              <p className="text-xs text-gray-500 mt-0.5">
                {item.student.enrollment_code}
                {item.student.email ? ` · ${item.student.email}` : ''}
              </p>
            </div>
            <div className="text-right">
              <p className="font-bold text-red-600">{fmt(item.total_overdue)}</p>
              <p className="text-xs text-gray-400">{item.records.length} parcela(s) em atraso</p>
            </div>
          </button>
          {expandido === item.student.id && (
            <div className="border-t bg-gray-50 px-5 py-3">
              <table className="w-full text-xs">
                <thead>
                  <tr className="text-gray-500">
                    <th className="text-left py-1 font-medium">Descrição</th>
                    <th className="text-right py-1 font-medium">Valor</th>
                    <th className="text-left py-1 font-medium">Vencimento</th>
                    <th className="text-left py-1 font-medium">Dias atraso</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {item.records.map(r => (
                    <tr key={r.id}>
                      <td className="py-1.5 text-gray-700">{r.description}</td>
                      <td className="py-1.5 text-right font-medium text-red-600">{fmt(r.amount)}</td>
                      <td className="py-1.5 text-gray-600">{r.due_date}</td>
                      <td className="py-1.5 text-gray-600">{r.days_overdue ?? '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      ))}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Aba: Relatório
// ──────────────────────────────────────────────────────────────
function AbaRelatorio() {
  const [mes, setMes] = useState(getMesAtual());
  const [resumo, setResumo] = useState<Resumo | null>(null);
  const [loading, setLoading] = useState(false);

  const carregar = useCallback(async () => {
    setLoading(true);
    const res = await fetch(`/api/financeiro/resumo?month=${mes}`);
    const data = await res.json();
    setResumo(data.data || null);
    setLoading(false);
  }, [mes]);

  useEffect(() => { carregar(); }, [carregar]);

  return (
    <div>
      <div className="flex items-center gap-4 mb-6">
        <label className="text-sm font-medium text-gray-700">Mês de referência:</label>
        <input
          type="month"
          value={mes}
          onChange={e => setMes(e.target.value)}
          className="border rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
        />
      </div>
      {loading ? (
        <div className="p-8 text-center text-gray-500">Carregando...</div>
      ) : resumo ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
          {[
            { label: 'Total cobrado', value: resumo.total, color: 'text-gray-900' },
            { label: 'Recebido (pago)', value: resumo.paid, color: 'text-green-700' },
            { label: 'Pendente', value: resumo.pending, color: 'text-yellow-700' },
            { label: 'Em atraso', value: resumo.overdue, color: 'text-red-700' },
            { label: 'Falhou / Estornado', value: resumo.failed, color: 'text-gray-500' },
          ].map(({ label, value, color }) => (
            <div key={label} className="bg-white rounded-xl border p-5">
              <p className="text-xs text-gray-500 mb-1">{label}</p>
              <p className={`text-2xl font-bold ${color}`}>{fmt(value)}</p>
            </div>
          ))}
          <div className="bg-white rounded-xl border p-5">
            <p className="text-xs text-gray-500 mb-1">Cobranças em atraso</p>
            <p className="text-2xl font-bold text-red-700">{resumo.overdue_count}</p>
          </div>
        </div>
      ) : (
        <div className="p-8 text-center text-gray-500">Nenhum dado para o mês selecionado.</div>
      )}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────
// Página principal
// ──────────────────────────────────────────────────────────────
export default function FinanceiroPage() {
  const [aba, setAba] = useState<Aba>('cobrancas');

  const abas: { id: Aba; label: string }[] = [
    { id: 'cobrancas', label: 'Cobranças' },
    { id: 'inadimplencia', label: 'Inadimplência' },
    { id: 'relatorio', label: 'Relatório' },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <a href="/dashboard" className="text-blue-600 hover:text-blue-700 text-sm">← Dashboard</a>
          <h1 className="text-xl font-bold text-gray-900">Financeiro</h1>
        </div>
        <a href="/login" className="text-sm text-gray-500 hover:text-gray-700">Sair</a>
      </nav>

      <main className="max-w-7xl mx-auto px-6 py-8">
        <div className="flex border-b border-gray-200 mb-6">
          {abas.map(a => (
            <button
              key={a.id}
              onClick={() => setAba(a.id)}
              className={`px-5 py-3 text-sm font-medium border-b-2 transition-colors ${
                aba === a.id
                  ? 'border-blue-600 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700'
              }`}
            >
              {a.label}
            </button>
          ))}
        </div>

        {aba === 'cobrancas' && <AbaCobrancas />}
        {aba === 'inadimplencia' && <AbaInadimplencia />}
        {aba === 'relatorio' && <AbaRelatorio />}
      </main>
    </div>
  );
}
