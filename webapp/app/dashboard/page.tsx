export default async function DashboardPage() {
  // Metrics are loaded client-side via API endpoints in production
  const metrics = { totalAlunos: 0, totalTurmas: 0, cobrancasPendentes: 0 };

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white border-b px-6 py-4 flex items-center justify-between">
        <h1 className="text-xl font-bold text-blue-600">Lexend Scholar</h1>
        <a href="/login" className="text-sm text-gray-500 hover:text-gray-700">Sair</a>
      </nav>
      <main className="max-w-7xl mx-auto px-6 py-8">
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Dashboard</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          {[
            { label: 'Alunos Matriculados', value: metrics.totalAlunos, color: 'blue', href: '/alunos' },
            { label: 'Turmas Ativas', value: metrics.totalTurmas, color: 'green', href: '/turmas' },
            { label: 'Cobranças Pendentes', value: metrics.cobrancasPendentes, color: 'amber', href: '/financeiro' },
          ].map(m => (
            <a key={m.label} href={m.href}
              className="bg-white rounded-xl border p-6 hover:shadow-md transition-shadow">
              <p className="text-sm font-medium text-gray-500">{m.label}</p>
              <p className="text-3xl font-bold text-gray-900 mt-2">{m.value}</p>
            </a>
          ))}
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { label: 'Alunos', href: '/alunos', icon: '👨‍🎓' },
            { label: 'Turmas', href: '/turmas', icon: '🏫' },
            { label: 'Financeiro', href: '/financeiro', icon: '💰' },
            { label: 'Portal Responsável', href: '/painel-responsavel', icon: '👨‍👩‍👧' },
          ].map(m => (
            <a key={m.label} href={m.href}
              className="bg-white border rounded-xl p-4 flex flex-col items-center gap-2 hover:shadow-md transition-shadow">
              <span className="text-2xl">{m.icon}</span>
              <span className="text-sm font-medium text-gray-700">{m.label}</span>
            </a>
          ))}
        </div>
      </main>
    </div>
  );
}
