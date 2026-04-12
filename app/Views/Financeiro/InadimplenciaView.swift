// LS-87: Implementar controle de inadimplência
import SwiftUI

struct InadimplenciaView: View {
    @State private var cobrancas: [Cobranca] = Cobranca.demo
    @State private var searchText = ""
    @State private var lembreteEnviado: String? = nil
    @State private var showLembrete = false

    private var vencendo7Dias: [Cobranca] {
        let limite = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return cobrancas.filter { c in
            c.status == .pendente && c.vencimento <= limite && c.vencimento >= Date()
        }
    }

    private var inadimplentes: [AlunoInadimplente] {
        let atrasadas = cobrancas.filter { $0.status == .atrasado }
        let agrupadas = Dictionary(grouping: atrasadas, by: { $0.alunoId })
        return agrupadas.map { alunoId, cobras in
            AlunoInadimplente(
                alunoId: alunoId,
                aluno: cobras.first?.aluno ?? "",
                turma: cobras.first?.turma ?? "",
                cobrancas: cobras.sorted { $0.vencimento < $1.vencimento }
            )
        }
        .filter { filtroAluno($0) }
        .sorted { $0.totalDevido > $1.totalDevido }
    }

    private func filtroAluno(_ a: AlunoInadimplente) -> Bool {
        searchText.isEmpty || a.aluno.localizedCaseInsensitiveContains(searchText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        SchoolSearchBar(text: $searchText, placeholder: "Buscar aluno inadimplente...")

                        if !vencendo7Dias.isEmpty {
                            alertaVencimento
                        }

                        if inadimplentes.isEmpty {
                            emptyState
                        } else {
                            resumoSection
                            inadimplentesSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                if showLembrete, let nome = lembreteEnviado {
                    lembreteSuccessBanner(nome: nome)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                        .zIndex(10)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Financeiro",
            title: "Inadimplência",
            subtitle: "\(inadimplentes.count) alunos · R$ \(String(format: "%.0f", inadimplentes.reduce(0) { $0 + $1.totalDevido })) em atraso"
        ) {
            EmptyView()
        }
        .padding(.top, 24)
    }

    // MARK: - Alerta Vencimento

    private var alertaVencimento: some View {
        SchoolCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(SchoolPalette.warning)
                    Text("Vencem nos próximos 7 dias")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                }

                ForEach(vencendo7Dias) { c in
                    HStack {
                        InitialAvatar(name: c.aluno, accent: SchoolPalette.warning, size: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.aluno)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text("Vence \(c.vencimento, style: .date)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                        Spacer()
                        Text(c.valor, format: .currency(code: "BRL"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.warning)
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(SchoolPalette.warning.opacity(0.3), lineWidth: 1.5)
        )
    }

    // MARK: - Resumo

    private var resumoSection: some View {
        HStack(spacing: 12) {
            resumoCard(
                label: "Alunos",
                value: "\(inadimplentes.count)",
                icon: "person.2.fill",
                color: SchoolPalette.danger
            )
            resumoCard(
                label: "Total Devido",
                value: "R$ \(String(format: "%.0f", inadimplentes.reduce(0) { $0 + $1.totalDevido }))",
                icon: "exclamationmark.triangle.fill",
                color: SchoolPalette.danger
            )
        }
    }

    private func resumoCard(label: String, value: String, icon: String, color: Color) -> some View {
        SchoolCard {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                }
            }
        }
    }

    // MARK: - Inadimplentes Section

    private var inadimplentesSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Alunos Inadimplentes")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)
                Spacer()
            }

            ForEach(inadimplentes) { inadimplente in
                InadimplentesCard(inadimplente: inadimplente) {
                    enviarLembrete(para: inadimplente.aluno)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(SchoolPalette.success)
            Text("Nenhum aluno inadimplente")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
            Text("Todas as cobranças estão em dia.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Actions

    private func enviarLembrete(para aluno: String) {
        lembreteEnviado = aluno
        withAnimation { showLembrete = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { showLembrete = false }
        }
    }

    private func lembreteSuccessBanner(nome: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "message.fill").foregroundStyle(SchoolPalette.primary)
            Text("Lembrete enviado para responsável de \(nome)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - AlunoInadimplente

struct AlunoInadimplente: Identifiable {
    let alunoId: String
    let aluno: String
    let turma: String
    let cobrancas: [Cobranca]

    var id: String { alunoId }

    var mesesAtraso: Int { cobrancas.count }

    var totalDevido: Double {
        cobrancas.reduce(0) { $0 + $1.valorComJuros }
    }

    var diasMaxAtraso: Int {
        cobrancas.map { $0.diasAtraso }.max() ?? 0
    }

    var mensagemLembrete: String {
        let meses = cobrancas.map { $0.competencia }.joined(separator: ", ")
        return """
        Prezado responsável,

        Informamos que o(a) aluno(a) \(aluno) possui \(mesesAtraso) mensalidade(s) em atraso (\(meses)).

        Valor total devido: R$ \(String(format: "%.2f", totalDevido))

        Por favor, entre em contato com a secretaria para regularizar a situação.

        Atenciosamente,
        Equipe Lexend Scholar
        """
    }
}

// MARK: - InadimplentesCard

struct InadimplentesCard: View {
    let inadimplente: AlunoInadimplente
    let onEnviarLembrete: () -> Void
    @State private var expandido = false

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.3)) { expandido.toggle() } } label: {
                HStack(spacing: 14) {
                    InitialAvatar(name: inadimplente.aluno, accent: SchoolPalette.danger, size: 44)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(inadimplente.aluno)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.primaryText)
                        Text("\(inadimplente.turma) · \(inadimplente.mesesAtraso) mês(es) em atraso")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(SchoolPalette.secondaryText)
                        Text("Maior atraso: \(inadimplente.diasMaxAtraso) dias")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.danger)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(inadimplente.totalDevido, format: .currency(code: "BRL"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.danger)
                        Image(systemName: expandido ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SchoolPalette.secondaryText)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if expandido {
                Divider().padding(.horizontal, 16)
                VStack(spacing: 8) {
                    ForEach(inadimplente.cobrancas) { c in
                        HStack {
                            Text(c.competencia)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            Spacer()
                            Text("\(c.diasAtraso) dias")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.danger)
                            Text(c.valorComJuros, format: .currency(code: "BRL"))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 12)

                Divider().padding(.horizontal, 16)
                ShareLink(
                    item: inadimplente.mensagemLembrete,
                    preview: SharePreview("Lembrete para \(inadimplente.aluno)")
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Enviar Lembrete ao Responsável")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(SchoolPalette.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .simultaneousGesture(TapGesture().onEnded { onEnviarLembrete() })
            }
        }
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(SchoolPalette.danger.opacity(0.25), lineWidth: 1.5)
        )
    }
}

#Preview {
    InadimplenciaView()
}
