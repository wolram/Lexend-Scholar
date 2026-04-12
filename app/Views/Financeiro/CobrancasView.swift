import SwiftUI
import Charts

// MARK: - Models

enum StatusCobranca: String, CaseIterable {
    case pendente = "Pendente"
    case pago = "Pago"
    case atrasado = "Atrasado"
    case cancelado = "Cancelado"

    var color: Color {
        switch self {
        case .pendente: return SchoolPalette.warning
        case .pago: return SchoolPalette.success
        case .atrasado: return SchoolPalette.danger
        case .cancelado: return SchoolPalette.secondaryText
        }
    }
}

struct Cobranca: Identifiable {
    let id: String
    let aluno: String
    let turma: String
    let descricao: String
    let valor: Double
    let vencimento: Date
    var status: StatusCobranca
    let accent: Color
    var diasAtraso: Int {
        guard status == .atrasado else { return 0 }
        let diff = Calendar.current.dateComponents([.day], from: vencimento, to: Date()).day ?? 0
        return max(0, diff)
    }
    var valorComJuros: Double {
        guard status == .atrasado, diasAtraso > 0 else { return valor }
        return valor * (1 + 0.00033 * Double(diasAtraso))
    }
}

// MARK: - CobrancasView

struct CobrancasView: View {
    @State private var cobrancas: [Cobranca] = Cobranca.demo
    @State private var selectedMes = Date()
    @State private var filtroStatus: StatusCobranca? = nil
    @State private var searchText = ""
    @State private var showGerarCobrancas = false
    @State private var isGenerating = false
    @State private var showGenerateSuccess = false

    private var filtradas: [Cobranca] {
        cobrancas.filter { c in
            let matchBusca = searchText.isEmpty || c.aluno.localizedCaseInsensitiveContains(searchText)
            let matchStatus = filtroStatus == nil || c.status == filtroStatus
            return matchBusca && matchStatus
        }
    }

    private var totalPendente: Double { cobrancas.filter { $0.status == .pendente || $0.status == .atrasado }.map { $0.valor }.reduce(0, +) }
    private var totalRecebido: Double { cobrancas.filter { $0.status == .pago }.map { $0.valor }.reduce(0, +) }

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        mesSelector
                        summaryCards
                        statusChart
                        filterSection
                        cobrancasList
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showGerarCobrancas) {
                GerarCobrancasSheet { gerado in
                    showGerarCobrancas = false
                    if gerado {
                        showGenerateSuccess = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { showGenerateSuccess = false }
                    }
                }
            }
            .overlay(alignment: .top) {
                if showGenerateSuccess {
                    successBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                        .zIndex(10)
                }
            }
        }
    }

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Financeiro",
            title: "Cobranças",
            subtitle: "\(cobrancas.count) cobranças · \(cobrancas.filter { $0.status == .atrasado }.count) atrasadas"
        ) {
            Button { showGerarCobrancas = true } label: {
                Label("Gerar", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(SchoolPalette.primary, in: Capsule())
            }
        }
        .padding(.top, 24)
    }

    private var mesSelector: some View {
        HStack(spacing: 12) {
            Button {
                selectedMes = Calendar.current.date(byAdding: .month, value: -1, to: selectedMes) ?? selectedMes
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SchoolPalette.primary)
            }
            Text(selectedMes, format: .dateTime.month(.wide).year())
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
                .frame(maxWidth: .infinity)
            Button {
                selectedMes = Calendar.current.date(byAdding: .month, value: 1, to: selectedMes) ?? selectedMes
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SchoolPalette.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(SchoolPalette.outline))
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(label: "A Receber", value: "R$ \(String(format: "%.0f", totalPendente))", color: SchoolPalette.warning, symbol: "clock.fill")
            summaryCard(label: "Recebido", value: "R$ \(String(format: "%.0f", totalRecebido))", color: SchoolPalette.success, symbol: "checkmark.circle.fill")
        }
    }

    private func summaryCard(label: String, value: String, color: Color, symbol: String) -> some View {
        SchoolCard {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                }
            }
        }
    }

    private var statusChart: some View {
        SchoolCard(title: "Distribuição de Status") {
            Chart {
                ForEach(StatusCobranca.allCases, id: \.self) { status in
                    let count = cobrancas.filter { $0.status == status }.count
                    if count > 0 {
                        SectorMark(
                            angle: .value("Qtd", count),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(status.color)
                        .cornerRadius(4)
                        .annotation(position: .overlay) {
                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .frame(height: 140)

            HStack(spacing: 12) {
                ForEach(StatusCobranca.allCases, id: \.self) { status in
                    HStack(spacing: 4) {
                        Circle().fill(status.color).frame(width: 8, height: 8)
                        Text(status.rawValue)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(SchoolPalette.secondaryText)
                    }
                }
            }
        }
    }

    private var filterSection: some View {
        VStack(spacing: 10) {
            SchoolSearchBar(text: $searchText, placeholder: "Buscar aluno...")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "Todos", color: SchoolPalette.secondaryText, isSelected: filtroStatus == nil) { filtroStatus = nil }
                    ForEach(StatusCobranca.allCases, id: \.self) { status in
                        filterChip(label: status.rawValue, color: status.color, isSelected: filtroStatus == status) {
                            filtroStatus = filtroStatus == status ? nil : status
                        }
                    }
                }
            }
        }
    }

    private func filterChip(label: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(isSelected ? color : color.opacity(0.1), in: Capsule())
        }
    }

    private var cobrancasList: some View {
        LazyVStack(spacing: 10) {
            ForEach(filtradas) { cobranca in
                CobrancaCard(cobranca: cobranca)
            }
        }
    }

    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(SchoolPalette.success)
            Text("Cobranças geradas com sucesso!")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }
}

// MARK: - CobrancaCard

struct CobrancaCard: View {
    let cobranca: Cobranca

    var body: some View {
        HStack(spacing: 14) {
            InitialAvatar(name: cobranca.aluno, accent: cobranca.accent, size: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text(cobranca.aluno)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)
                Text(cobranca.descricao)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                if cobranca.status == .atrasado && cobranca.diasAtraso > 0 {
                    Text("\(cobranca.diasAtraso) dias em atraso")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.danger)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("R$ \(String(format: "%.2f", cobranca.status == .atrasado ? cobranca.valorComJuros : cobranca.valor))")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)
                StatusChip(text: cobranca.status.rawValue, color: cobranca.status.color)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(cobranca.status == .atrasado ? SchoolPalette.danger.opacity(0.3) : SchoolPalette.outline))
    }
}

// MARK: - GerarCobrancasSheet

struct GerarCobrancasSheet: View {
    let onComplete: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var mesSelecionado = Date()
    @State private var turmasSelecionadas: Set<String> = ["1º Ano A", "2º Ano B", "3º Ano C"]
    @State private var isGenerating = false

    private let todasTurmas = ["1º Ano A", "1º Ano B", "2º Ano A", "2º Ano B", "3º Ano A", "3º Ano C"]

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        SchoolCard(title: "Gerar Cobranças Mensais") {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Mês de Referência")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)
                                    DatePicker("", selection: $mesSelecionado, displayedComponents: [.date])
                                        .labelsHidden()
                                        .tint(SchoolPalette.primary)
                                }
                                Divider()
                                Text("Selecionar Turmas")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)
                                ForEach(todasTurmas, id: \.self) { turma in
                                    Button {
                                        if turmasSelecionadas.contains(turma) {
                                            turmasSelecionadas.remove(turma)
                                        } else {
                                            turmasSelecionadas.insert(turma)
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: turmasSelecionadas.contains(turma) ? "checkmark.square.fill" : "square")
                                                .foregroundStyle(turmasSelecionadas.contains(turma) ? SchoolPalette.primary : SchoolPalette.secondaryText)
                                            Text(turma)
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundStyle(SchoolPalette.primaryText)
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        Button {
                            isGenerating = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isGenerating = false
                                onComplete(true)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if isGenerating { ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.8) }
                                Text(isGenerating ? "Gerando..." : "Gerar \(turmasSelecionadas.count) Turmas")
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(turmasSelecionadas.isEmpty ? SchoolPalette.outline : SchoolPalette.primary, in: RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                        }
                        .disabled(turmasSelecionadas.isEmpty || isGenerating)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Gerar Cobranças")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { onComplete(false) }.tint(SchoolPalette.secondaryText)
                }
            }
        }
    }
}

// MARK: - Demo Data

extension Cobranca {
    static let demo: [Cobranca] = {
        let cal = Calendar.current
        let base = Date()
        func d(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: base) ?? base }
        return [
            Cobranca(id: "cb-1", aluno: "Sophia Anderson", turma: "1º Ano A", descricao: "Mensalidade Abril/2026", valor: 850.00, vencimento: d(-5), status: .pago, accent: SchoolPalette.primary),
            Cobranca(id: "cb-2", aluno: "Elena Rodriguez", turma: "2º Ano B", descricao: "Mensalidade Abril/2026", valor: 1_200.00, vencimento: d(5), status: .pendente, accent: SchoolPalette.violet),
            Cobranca(id: "cb-3", aluno: "Jordan Lee", turma: "3º Ano C", descricao: "Mensalidade Março/2026", valor: 850.00, vencimento: d(-20), status: .atrasado, accent: SchoolPalette.warning),
            Cobranca(id: "cb-4", aluno: "Gabriel Souza", turma: "1º Ano A", descricao: "Mensalidade Abril/2026", valor: 425.00, vencimento: d(10), status: .pendente, accent: SchoolPalette.success),
            Cobranca(id: "cb-5", aluno: "Isabella Martins", turma: "2º Ano B", descricao: "Mensalidade Fevereiro/2026", valor: 1_200.00, vencimento: d(-40), status: .atrasado, accent: SchoolPalette.danger),
            Cobranca(id: "cb-6", aluno: "Lucas Ferreira", turma: "3º Ano C", descricao: "Mensalidade Abril/2026", valor: 850.00, vencimento: d(5), status: .pago, accent: SchoolPalette.primary)
        ]
    }()
}

#Preview {
    CobrancasView()
}
