// LS-85: Implementar geração de cobranças mensais
import SwiftUI
import Charts

// MARK: - CobrancasView

struct CobrancasView: View {
    @State private var cobrancas: [Cobranca] = Cobranca.demo
    @State private var selectedMes = Date()
    @State private var filtroStatus: StatusCobranca? = nil
    @State private var searchText = ""
    @State private var showGerarCobrancas = false
    @State private var showGenerateSuccess = false
    @State private var selectedCobranca: Cobranca? = nil
    @State private var showRegistrarPagamento = false
    @State private var showRecibo = false
    @State private var reciboCobranca: Cobranca? = nil

    private var filtradas: [Cobranca] {
        cobrancas.filter { c in
            let matchBusca = searchText.isEmpty || c.aluno.localizedCaseInsensitiveContains(searchText)
            let matchStatus = filtroStatus == nil || c.status == filtroStatus
            return matchBusca && matchStatus
        }
    }

    private var totalPendente: Double {
        cobrancas.filter { $0.status == .pendente || $0.status == .atrasado }.map { $0.valor }.reduce(0, +)
    }
    private var totalRecebido: Double {
        cobrancas.filter { $0.status == .pago }.map { $0.valorPago ?? $0.valor }.reduce(0, +)
    }
    private var totalAtrasado: Double {
        cobrancas.filter { $0.status == .atrasado }.map { $0.valorComJuros }.reduce(0, +)
    }

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
                        withAnimation { showGenerateSuccess = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { showGenerateSuccess = false }
                        }
                    }
                }
            }
            .sheet(isPresented: $showRegistrarPagamento) {
                if let cobranca = selectedCobranca {
                    RegistrarPagamentoView(cobranca: cobranca) { paga in
                        if let idx = cobrancas.firstIndex(where: { $0.id == paga.id }) {
                            cobrancas[idx] = paga
                        }
                        showRegistrarPagamento = false
                        reciboCobranca = paga
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showRecibo = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showRecibo) {
                if let cobranca = reciboCobranca {
                    ReciboView(cobranca: cobranca)
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

    // MARK: - Header

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Financeiro",
            title: "Cobranças",
            subtitle: "\(cobrancas.count) cobranças · \(cobrancas.filter { $0.status == .atrasado }.count) atrasadas"
        ) {
            Button { showGerarCobrancas = true } label: {
                Label("Gerar Cobranças do Mês", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(SchoolPalette.primary, in: Capsule())
            }
        }
        .padding(.top, 24)
    }

    // MARK: - Mes Selector

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

    // MARK: - Summary Cards

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                summaryCard(label: "Recebido", value: totalRecebido, color: SchoolPalette.success, symbol: "checkmark.circle.fill")
                summaryCard(label: "A Receber", value: totalPendente, color: SchoolPalette.warning, symbol: "clock.fill")
            }
            summaryCard(label: "Em Atraso", value: totalAtrasado, color: SchoolPalette.danger, symbol: "exclamationmark.triangle.fill")
                .frame(maxWidth: .infinity)
        }
    }

    private func summaryCard(label: String, value: Double, color: Color, symbol: String) -> some View {
        SchoolCard {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(color)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                    Text(value, format: .currency(code: "BRL"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                }
            }
        }
    }

    // MARK: - Status Chart

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
                    let count = cobrancas.filter { $0.status == status }.count
                    if count > 0 {
                        HStack(spacing: 4) {
                            Circle().fill(status.color).frame(width: 8, height: 8)
                            Text("\(status.rawValue) (\(count))")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filter Section

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

    // MARK: - Cobrancas List

    private var cobrancasList: some View {
        LazyVStack(spacing: 10) {
            if filtradas.isEmpty {
                emptyState
            } else {
                ForEach(filtradas) { cobranca in
                    CobrancaCard(cobranca: cobranca) {
                        selectedCobranca = cobranca
                        showRegistrarPagamento = true
                    } onVerRecibo: {
                        reciboCobranca = cobranca
                        showRecibo = true
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(SchoolPalette.secondaryText.opacity(0.5))
            Text("Nenhuma cobrança encontrada")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(SchoolPalette.success)
            Text("Cobranças do mês geradas com sucesso!")
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
    let onPagar: () -> Void
    let onVerRecibo: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                InitialAvatar(name: cobranca.aluno, accent: cobranca.accent, size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(cobranca.aluno)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                    Text("\(cobranca.turma) · \(cobranca.competencia)")
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
                    Text(cobranca.status == .atrasado ? cobranca.valorComJuros : cobranca.valor, format: .currency(code: "BRL"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                    StatusChip(text: cobranca.status.rawValue, color: cobranca.status.color)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            if cobranca.status == .pendente || cobranca.status == .atrasado {
                Divider().padding(.horizontal, 16)
                Button(action: onPagar) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Registrar Pagamento")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(SchoolPalette.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            } else if cobranca.status == .pago {
                Divider().padding(.horizontal, 16)
                Button(action: onVerRecibo) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Ver Recibo")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(SchoolPalette.success)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(cobranca.status == .atrasado ? SchoolPalette.danger.opacity(0.3) : SchoolPalette.outline)
        )
    }
}

// MARK: - GerarCobrancasSheet

struct GerarCobrancasSheet: View {
    let onComplete: (Bool) -> Void
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
                        SchoolCard(title: "Gerar Cobranças Mensais", subtitle: "Selecione o mês e as turmas para gerar cobranças automaticamente") {
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
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                }
                                Text(isGenerating ? "Gerando..." : "Gerar Cobranças — \(turmasSelecionadas.count) Turma(s)")
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                turmasSelecionadas.isEmpty ? SchoolPalette.outline : SchoolPalette.primary,
                                in: RoundedRectangle(cornerRadius: 16)
                            )
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
                    Button("Cancelar") { onComplete(false) }
                        .tint(SchoolPalette.secondaryText)
                }
            }
        }
    }
}

#Preview {
    CobrancasView()
}
