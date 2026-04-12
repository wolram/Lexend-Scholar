'use client';
import { useState, useEffect } from 'react';

interface Aluno {
  id: string;
  nome: string;
  turma?: string;
  serie?: string;
  status?: string;
}

export default function AlunosPage() {
  const [alunos, setAlunos] = useState<Aluno[]>([]);
  const [busca, setBusca] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/crud-academico/alunos')
      .then(r => r.json())
      .then(data => {
        setAlunos(Array.isArray(data) ? data : data.data || []);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const filtrados = alunos.filter(a =>
    a.nome?.toLowerCase().includes(busca.toLowerCase())
  );

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <a href="/dashboard" className="text-blue-600 hover:text-blue-700 text-sm">← Dashboard</a>
          <h1 className="text-xl font-bold text-gray-900">Alunos</h1>
        </div>
        <a href="/login" className="text-sm text-gray-500 hover:text-gray-700">Sair</a>
      </nav>
      <main className="max-w-7xl mx-auto px-6 py-8">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-2xl font-bold text-gray-900">Alunos Matriculados</h2>
          <button className="bg-blue-600 text-white px-4 py-2 rounded-lg font-semibold hover:bg-blue-700 transition-colors text-sm">
            + Novo Aluno
          </button>
        </div>
        <div className="mb-4">
          <input
            type="text"
            placeholder="Buscar por nome..."
            value={busca}
            onChange={e => setBusca(e.target.value)}
            className="w-full max-w-md border border-gray-300 rounded-lg px-4 py-2 focus:ring-2 focus:ring-blue-500 outline-none"
          />
        </div>
        <div className="bg-white rounded-xl border overflow-hidden">
          {loading ? (
            <div className="p-8 text-center text-gray-500">Carregando...</div>
          ) : filtrados.length === 0 ? (
            <div className="p-8 text-center text-gray-500">Nenhum aluno encontrado.</div>
          ) : (
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Nome</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Turma</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Série</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Status</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Ações</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filtrados.map(aluno => (
                  <tr key={aluno.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 font-medium text-gray-900">{aluno.nome}</td>
                    <td className="px-4 py-3 text-gray-600">{aluno.turma || '—'}</td>
                    <td className="px-4 py-3 text-gray-600">{aluno.serie || '—'}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${
                        aluno.status === 'ativo' ? 'bg-green-100 text-green-700' :
                        aluno.status === 'inativo' ? 'bg-red-100 text-red-700' :
                        'bg-gray-100 text-gray-600'
                      }`}>
                        {aluno.status || 'ativo'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex gap-2">
                        <a href={`/alunos/${aluno.id}`} className="text-blue-600 hover:text-blue-700 font-medium">Ver</a>
                        <span className="text-gray-300">|</span>
                        <a href={`/alunos/${aluno.id}`} className="text-gray-600 hover:text-gray-700 font-medium">Editar</a>
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
