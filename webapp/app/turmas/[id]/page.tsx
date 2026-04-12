'use client';
import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';

interface Turma {
  id: string;
  nome: string;
  serie?: string;
  professor?: string;
}

interface Aluno {
  id: string;
  nome: string;
  status?: string;
}

export default function TurmaDetalhePage() {
  const params = useParams();
  const id = params?.id as string;
  const [turma, setTurma] = useState<Turma | null>(null);
  const [alunos, setAlunos] = useState<Aluno[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    Promise.allSettled([
      fetch(`/api/crud-academico/turmas/${id}`).then(r => r.json()),
      fetch(`/api/crud-academico/alunos?turma_id=${id}`).then(r => r.json()),
    ]).then(([turmaRes, alunosRes]) => {
      if (turmaRes.status === 'fulfilled') setTurma(turmaRes.value.data || turmaRes.value);
      if (alunosRes.status === 'fulfilled') setAlunos(Array.isArray(alunosRes.value) ? alunosRes.value : alunosRes.value.data || []);
      setLoading(false);
    });
  }, [id]);

  if (loading) return <div className="min-h-screen flex items-center justify-center text-gray-500">Carregando...</div>;

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <a href="/dashboard" className="hover:text-blue-600">Dashboard</a>
          <span>›</span>
          <a href="/turmas" className="hover:text-blue-600">Turmas</a>
          <span>›</span>
          <span className="text-gray-900 font-medium">{turma?.nome || id}</span>
        </div>
        <a href="/login" className="text-sm text-gray-500 hover:text-gray-700">Sair</a>
      </nav>
      <main className="max-w-4xl mx-auto px-6 py-8">
        {turma && (
          <div className="bg-white rounded-xl border p-6 mb-6">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-2xl font-bold text-gray-900">{turma.nome}</h1>
                <p className="text-gray-500 text-sm mt-1">
                  {turma.serie && `Série: ${turma.serie}`}
                  {turma.professor && ` · Professor: ${turma.professor}`}
                </p>
              </div>
              <a href={`/turmas/${id}/frequencia`}
                className="bg-green-600 text-white px-4 py-2 rounded-lg font-semibold hover:bg-green-700 transition-colors text-sm">
                Lançar Frequência
              </a>
            </div>
          </div>
        )}

        <div className="bg-white rounded-xl border overflow-hidden">
          <div className="px-6 py-4 border-b">
            <h2 className="font-semibold text-gray-900">Alunos da Turma ({alunos.length})</h2>
          </div>
          {alunos.length === 0 ? (
            <div className="p-8 text-center text-gray-500">Nenhum aluno nesta turma.</div>
          ) : (
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Nome</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Status</th>
                  <th className="px-4 py-3 text-left font-semibold text-gray-600">Ações</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {alunos.map(aluno => (
                  <tr key={aluno.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 font-medium text-gray-900">{aluno.nome}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${
                        aluno.status === 'ativo' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
                      }`}>
                        {aluno.status || 'ativo'}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <a href={`/alunos/${aluno.id}`} className="text-blue-600 hover:text-blue-700 font-medium">Ver perfil</a>
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
