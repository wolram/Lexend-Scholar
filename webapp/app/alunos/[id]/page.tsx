'use client';
import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';

const TABS = ['Dados Pessoais', 'Acadêmico', 'Financeiro', 'Documentos'] as const;
type Tab = typeof TABS[number];

interface AlunoDetalhe {
  id: string;
  nome: string;
  email?: string;
  telefone?: string;
  data_nascimento?: string;
  cpf?: string;
  endereco?: string;
  turma?: string;
  serie?: string;
  status?: string;
  matricula?: string;
}

export default function AlunoPerfilPage() {
  const params = useParams();
  const id = params?.id as string;
  const [aluno, setAluno] = useState<AlunoDetalhe | null>(null);
  const [abaAtiva, setAbaAtiva] = useState<Tab>('Dados Pessoais');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    fetch(`/api/crud-academico/alunos/${id}`)
      .then(r => r.json())
      .then(data => { setAluno(data.data || data); setLoading(false); })
      .catch(() => setLoading(false));
  }, [id]);

  if (loading) return <div className="min-h-screen flex items-center justify-center text-gray-500">Carregando...</div>;
  if (!aluno) return <div className="min-h-screen flex items-center justify-center text-gray-500">Aluno não encontrado.</div>;

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-2 text-sm text-gray-500">
          <a href="/dashboard" className="hover:text-blue-600">Dashboard</a>
          <span>›</span>
          <a href="/alunos" className="hover:text-blue-600">Alunos</a>
          <span>›</span>
          <span className="text-gray-900 font-medium">{aluno.nome}</span>
        </div>
        <a href="/login" className="text-sm text-gray-500 hover:text-gray-700">Sair</a>
      </nav>
      <main className="max-w-4xl mx-auto px-6 py-8">
        <div className="bg-white rounded-xl border mb-6 p-6">
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-full bg-blue-100 flex items-center justify-center text-2xl font-bold text-blue-600">
              {aluno.nome?.charAt(0)?.toUpperCase()}
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">{aluno.nome}</h1>
              <p className="text-gray-500 text-sm">{aluno.turma && `Turma: ${aluno.turma}`} {aluno.serie && `· ${aluno.serie}`}</p>
              {aluno.matricula && <p className="text-gray-400 text-xs mt-0.5">Matrícula: {aluno.matricula}</p>}
            </div>
            <span className={`ml-auto inline-flex px-3 py-1 rounded-full text-sm font-medium ${
              aluno.status === 'ativo' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
            }`}>
              {aluno.status || 'ativo'}
            </span>
          </div>
        </div>

        {/* Abas */}
        <div className="bg-white rounded-xl border overflow-hidden">
          <div className="border-b flex">
            {TABS.map(tab => (
              <button
                key={tab}
                onClick={() => setAbaAtiva(tab)}
                className={`px-5 py-3 text-sm font-medium transition-colors ${
                  abaAtiva === tab
                    ? 'text-blue-600 border-b-2 border-blue-600'
                    : 'text-gray-500 hover:text-gray-700'
                }`}
              >
                {tab}
              </button>
            ))}
          </div>
          <div className="p-6">
            {abaAtiva === 'Dados Pessoais' && (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {[
                  { label: 'Nome completo', value: aluno.nome },
                  { label: 'Email', value: aluno.email },
                  { label: 'Telefone', value: aluno.telefone },
                  { label: 'Data de nascimento', value: aluno.data_nascimento },
                  { label: 'CPF', value: aluno.cpf },
                  { label: 'Endereço', value: aluno.endereco },
                ].map(item => (
                  <div key={item.label}>
                    <p className="text-xs font-medium text-gray-500 uppercase tracking-wide">{item.label}</p>
                    <p className="text-gray-900 mt-0.5">{item.value || '—'}</p>
                  </div>
                ))}
              </div>
            )}
            {abaAtiva === 'Acadêmico' && (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {[
                  { label: 'Turma', value: aluno.turma },
                  { label: 'Série', value: aluno.serie },
                  { label: 'Matrícula', value: aluno.matricula },
                  { label: 'Status', value: aluno.status },
                ].map(item => (
                  <div key={item.label}>
                    <p className="text-xs font-medium text-gray-500 uppercase tracking-wide">{item.label}</p>
                    <p className="text-gray-900 mt-0.5">{item.value || '—'}</p>
                  </div>
                ))}
              </div>
            )}
            {abaAtiva === 'Financeiro' && (
              <div className="text-gray-500 text-sm">
                <p>Histórico financeiro disponível em <a href="/financeiro" className="text-blue-600 hover:underline">Módulo Financeiro</a>.</p>
              </div>
            )}
            {abaAtiva === 'Documentos' && (
              <div className="text-gray-500 text-sm">
                <p>Documentos do aluno serão exibidos aqui quando disponíveis via API.</p>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
