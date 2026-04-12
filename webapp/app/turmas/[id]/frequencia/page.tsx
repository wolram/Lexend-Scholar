'use client';
import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';

type StatusFrequencia = 'P' | 'F' | 'J';

interface Aluno {
  id: string;
  nome: string;
}

function getDiasUteis(): number[] {
  const hoje = new Date();
  const ano = hoje.getFullYear();
  const mes = hoje.getMonth();
  const totalDias = new Date(ano, mes + 1, 0).getDate();
  const dias: number[] = [];
  for (let d = 1; d <= totalDias; d++) {
    const dia = new Date(ano, mes, d).getDay();
    if (dia !== 0 && dia !== 6) dias.push(d);
  }
  return dias;
}

const STATUS_COLORS: Record<StatusFrequencia, string> = {
  P: 'bg-green-100 text-green-700 border-green-200',
  F: 'bg-red-100 text-red-700 border-red-200',
  J: 'bg-yellow-100 text-yellow-700 border-yellow-200',
};

export default function FrequenciaPage() {
  const params = useParams();
  const id = params?.id as string;
  const [alunos, setAlunos] = useState<Aluno[]>([]);
  const [frequencia, setFrequencia] = useState<Record<string, Record<number, StatusFrequencia>>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const diasUteis = getDiasUteis();

  const mesAtual = new Date().toLocaleString('pt-BR', { month: 'long', year: 'numeric' });

  useEffect(() => {
    if (!id) return;
    fetch(`/api/crud-academico/alunos?turma_id=${id}`)
      .then(r => r.json())
      .then(data => {
        const lista: Aluno[] = Array.isArray(data) ? data : data.data || [];
        setAlunos(lista);
        const freq: Record<string, Record<number, StatusFrequencia>> = {};
        lista.forEach(a => {
          freq[a.id] = {};
          diasUteis.forEach(d => { freq[a.id][d] = 'P'; });
        });
        setFrequencia(freq);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [id]);

  function toggleStatus(alunoId: string, dia: number) {
    setFrequencia(prev => {
      const atual = prev[alunoId]?.[dia] || 'P';
      const proximo: StatusFrequencia = atual === 'P' ? 'F' : atual === 'F' ? 'J' : 'P';
      return { ...prev, [alunoId]: { ...prev[alunoId], [dia]: proximo } };
    });
  }

  async function salvarFrequencia() {
    setSaving(true);
    try {
      await fetch('/api/matriculas-frequencia', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ turma_id: id, frequencia }),
      });
      alert('Frequência salva com sucesso!');
    } catch {
      alert('Erro ao salvar frequência.');
    } finally {
      setSaving(false);
    }
  }

  if (loading) return <div className="min-h-screen flex items-center justify-center text-gray-500">Carregando...</div>;

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <a href="/turmas" className="hover:text-blue-600">Turmas</a>
          <span>›</span>
          <a href={`/turmas/${id}`} className="hover:text-blue-600">Turma</a>
          <span>›</span>
          <span className="text-gray-900 font-medium">Frequência</span>
        </div>
        <a href="/login" className="text-sm text-gray-500 hover:text-gray-700">Sair</a>
      </nav>
      <main className="max-w-full mx-auto px-6 py-8">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-2xl font-bold text-gray-900">Lançamento de Frequência</h2>
            <p className="text-gray-500 text-sm mt-1 capitalize">{mesAtual}</p>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex gap-2 text-xs">
              {(['P', 'F', 'J'] as StatusFrequencia[]).map(s => (
                <span key={s} className={`px-2 py-0.5 rounded border font-medium ${STATUS_COLORS[s]}`}>
                  {s === 'P' ? 'Presente' : s === 'F' ? 'Falta' : 'Justificado'}
                </span>
              ))}
            </div>
            <button
              onClick={salvarFrequencia}
              disabled={saving}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg font-semibold hover:bg-blue-700 disabled:opacity-60 transition-colors text-sm"
            >
              {saving ? 'Salvando...' : 'Salvar Frequência'}
            </button>
          </div>
        </div>

        {alunos.length === 0 ? (
          <div className="bg-white rounded-xl border p-8 text-center text-gray-500">Nenhum aluno encontrado nesta turma.</div>
        ) : (
          <div className="bg-white rounded-xl border overflow-x-auto">
            <table className="text-xs min-w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600 sticky left-0 bg-gray-50 min-w-[180px]">Aluno</th>
                  {diasUteis.map(d => (
                    <th key={d} className="px-2 py-3 text-center font-semibold text-gray-600 min-w-[36px]">{d}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {alunos.map(aluno => (
                  <tr key={aluno.id} className="hover:bg-gray-50">
                    <td className="px-4 py-2 font-medium text-gray-900 sticky left-0 bg-white">{aluno.nome}</td>
                    {diasUteis.map(d => {
                      const status = frequencia[aluno.id]?.[d] || 'P';
                      return (
                        <td key={d} className="px-1 py-2 text-center">
                          <button
                            onClick={() => toggleStatus(aluno.id, d)}
                            className={`w-8 h-8 rounded border font-bold transition-colors ${STATUS_COLORS[status]}`}
                            title={`${aluno.nome} - Dia ${d}: ${status}`}
                          >
                            {status}
                          </button>
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </div>
  );
}
