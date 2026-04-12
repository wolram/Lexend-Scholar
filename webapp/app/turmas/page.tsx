'use client';
import { useState, useEffect } from 'react';

interface Turma {
  id: string;
  nome: string;
  serie?: string;
  professor?: string;
  total_alunos?: number;
}

export default function TurmasPage() {
  const [turmas, setTurmas] = useState<Turma[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/crud-academico/turmas')
      .then(r => r.json())
      .then(data => {
        setTurmas(Array.isArray(data) ? data : data.data || []);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <a href="/dashboard" className="text-blue-600 hover:text-blue-700 text-sm">← Dashboard</a>
          <h1 className="text-xl font-bold text-gray-900">Turmas</h1>
        </div>
        <a href="/login" className="text-sm text-gray-500 hover:text-gray-700">Sair</a>
      </nav>
      <main className="max-w-7xl mx-auto px-6 py-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Turmas Ativas</h2>
          <button className="bg-blue-600 text-white px-4 py-2 rounded-lg font-semibold hover:bg-blue-700 transition-colors text-sm">
            + Nova Turma
          </button>
        </div>
        <div className="bg-white rounded-xl border overflow-hidden">
          {loading ? (
            <div className="p-8 text-center text-gray-500">Carregando...</div>
          ) : turmas.length === 0 ? (
            <div className="p-8 text-center text-gray-500">Nenhuma turma encontrada.</div>
          ) : (
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Nome</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Série</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Professor</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Nº Alunos</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Ações</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {turmas.map(turma => (
                  <tr key={turma.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 font-medium text-gray-900">{turma.nome}</td>
                    <td className="px-4 py-3 text-gray-600">{turma.serie || '—'}</td>
                    <td className="px-4 py-3 text-gray-600">{turma.professor || '—'}</td>
                    <td className="px-4 py-3 text-gray-600">{turma.total_alunos ?? '—'}</td>
                    <td className="px-4 py-3">
                      <div className="flex gap-2">
                        <a href={`/turmas/${turma.id}`} className="text-blue-600 hover:text-blue-700 font-medium">Ver</a>
                        <span className="text-gray-300">|</span>
                        <a href={`/turmas/${turma.id}/frequencia`} className="text-green-600 hover:text-green-700 font-medium">Frequência</a>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </main>
    </div>
  );
}
