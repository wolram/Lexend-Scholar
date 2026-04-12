// LS-89: Implementar relatório financeiro geral
import SwiftUI
import Charts

struct RelatorioFinanceiroView: View {
    @State private var cobrancas: [Cobranca] = Cobranca.demo
    @State private var filtroStatus: StatusCobranca? = nil

    // MARK: - Computed

    private var cobrancasFiltradas: [Cobranca] {
        guard let filtro = filtroStatus else { return cobrancas }
        return cobrancas.filter { $0.status == filtro }
    }

    private var totalArrecadadoMes: Double {
        cobrancas
            .filter { $0.status == .pago }
            .reduce(0) { $0 + ($1.valorPago ?? $1.valor) }
    }

    private var totalAReceber: Double {
        cobrancas.filter { $0.status == .pendente }.reduce(0) { $0 + $1.valor }
    }

    private var totalEmAtraso: Double {
        cobrancas.filter { $0.status == .atrasado }.reduce(0) { $0 + $1.valorComJuros }
    }

    private var dadosGrafico: [DadosMes] {
        // Últimos 6 meses com dados simulados
        let cal = Calendar.current
        return (0..<6).reversed().map { offset -> DadosMes in
            let date = cal.date(byAdding: .month, value: -offset, to: Date()) ?? Date()
            let components = cal.dateComponents([.month, .year], from: date)
            let mes = components.month ?? 1
            let ano = components.year ?? 2026

            // Filtrar cobranças pagas nesse mês/ano
            let arrecadado = cobrancas
                .filter { c in
                    c.status == .pago && c.mes == mes && c.ano == ano
                }
                .reduce(0) { $0 + ($1.valorPago ?? $1.valor) }

            // Simulação para meses sem dados reais
            let simulado = offset == 0 ? arrecadado : Double.random(in: 3_000...8_000)

            let label: String = {
                let names = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun",
                             "Jul", "Ago", "Set", "Out", "Nov", "Dez"]
                return names[mes - 1]
            }()

            return DadosMes(
                label: label,
                mes: mes,
                ano: ano,
                arrecadado: offset == 0 ? totalArrecadadoMes : simulado
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        cardsResumo
                        graficoArrecadacao
                        listaCobrancas
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Financeiro",
            title: "Relatório",
            subtitle: "Visão geral da arrecadação escolar"
        ) {
            EmptyView()
        }
        .padding(.top, 24)
    }

    // MARK: - Cards Resumo

    private var cardsResumo: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                resumoCard(
                    label: "Arrecadado no Mês",
                    value: totalArrecadadoMes,
                    icon: "checkmark.circle.fill",
                    color: SchoolPalette.success
                )
                resumoCard(
                    label: "A Receber",
                    value: totalAReceber,
                    icon: "clock.fill",
                    color: SchoolPalette.warning
                )
            }
            resumoCard(
                label: "Em Atraso",
                value: totalEmAtraso,
                icon: "exclamationmark.triangle.fill",
                color: SchoolPalette.danger
            )
            .frame(maxWidth: .infinity)

            // Taxa de adimplência
            let total = cobrancas.count
            let pagos = cobrancas.filter { $0.status == .pago }.count
            let taxa = total > 0 ? Double(pagos) / Double(total) * 100 : 0

            SchoolCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Taxa de Adimplência")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(SchoolPalette.primaryText)
                        Spacer()
                        Text(String(format: "%.0f%%", taxa))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(taxa >= 70 ? SchoolPalette.success : SchoolPalette.danger)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(SchoolPalette.outline)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(taxa >= 70 ? SchoolPalette.success : SchoolPalette.danger)
                                .frame(width: geo.size.width * (taxa / 100), height: 8)
                                .animation(.spring(response: 0.6), value: taxa)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    private func resumoCard(label: String, value: Double, icon: String, color: Color) -> some View {
        SchoolCard {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(color)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(value, format: .currency(code: "BRL"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                }
            }
        }
    }

    // MARK: - Grafico

    private var graficoArrecadacao: some View {
        SchoolCard(title: "Arrecadação — Últimos 6 Meses") {
            Chart(dadosGrafico) { dado in
                BarMark(
                    x: .value("Mês", dado.label),
                    y: .value("Valor", dado.arrecadado)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [SchoolPalette.primary, SchoolPalette.violet],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
                .annotation(position: .top) {
                    if dado.arrecadado > 0 {
                        Text("R$\(String(format: "%.0f", dado.arrecadado / 1000))k")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.secondaryText)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("R$\(String(format: "%.0f", v / 1000))k")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(SchoolPalette.outline)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
            }
            .frame(height: 180)
        }
    }

    // MARK: - Lista Cobranças

    private var listaCobrancas: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Cobranças por Status")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)
                Spacer()
            }

            // Filtros
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filtroChip(label: "Todos", color: SchoolPalette.secondaryText, selecionado: filtroStatus == nil) {
                        filtroStatus = nil
                    }
                    ForEach(StatusCobranca.allCases, id: \.self) { status in
                        let count = cobrancas.filter { $0.status == status }.count
                        filtroChip(
                            label: "\(status.rawValue) (\(count))",
                            color: status.color,
                            selecionado: filtroStatus == status
                        ) {
                            filtroStatus = filtroStatus == status ? nil : status
                        }
                    }
                }
            }

            LazyVStack(spacing: 8) {
                ForEach(cobrancasFiltradas) { c in
                    HStack(spacing: 12) {
                        InitialAvatar(name: c.aluno, accent: c.accent, size: 38)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.aluno)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text("\(c.turma) · \(c.competencia)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(c.status == .atrasado ? c.valorComJuros : c.valor, format: .currency(code: "BRL"))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            StatusChip(text: c.status.rawValue, color: c.status.color)
                        }
                    }
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(SchoolPalette.outline, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func filtroChip(label: String, color: Color, selecionado: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(selecionado ? .white : color)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(selecionado ? color : color.opacity(0.1), in: Capsule())
        }
    }
}

// MARK: - DadosMes

struct DadosMes: Identifiable {
    let id = UUID()
    let label: String
    let mes: Int
    let ano: Int
    let arrecadado: Double
}

#Preview {
    RelatorioFinanceiroView()
}
