import SwiftUI
import Charts

// MARK: - Models

struct NotaAluno: Identifiable {
    let id: String
    let nome: String
    let accent: Color
    var av1: Double?
    var av2: Double?
    var av3: Double?
    var recuperacao: Double?

    var media: Double? {
        let notas = [av1, av2, av3].compactMap { $0 }
        guard !notas.isEmpty else { return nil }
        let soma = notas.reduce(0, +)
        let media = soma / Double(notas.count)
        if let rec = recuperacao {
            return (media + rec) / 2
        }
        return media
    }

    var situacao: String {
        guard let m = media else { return "—" }
        if m >= 7.0 { return "Aprovado" }
        if m >= 5.0 { return "Recuperação" }
        return "Reprovado"
    }

    var situacaoColor: Color {
        guard let m = media else { return SchoolPalette.secondaryText }
        if m >= 7.0 { return SchoolPalette.success }
        if m >= 5.0 { return SchoolPalette.warning }
        return SchoolPalette.danger
    }
}

// MARK: - NotasLancamentoView

struct NotasLancamentoView: View {
    @State private var alunos: [NotaAluno] = NotaAluno.demo
    @State private var selectedDisciplina = "Matemática"
    @State private var selectedBimestre = "1º Bimestre"
    @State private var searchText = ""
    @State private var isSaving = false
    @State private var showSavedBanner = false
    @State private var showChart = false

    private let disciplinas = ["Matemática", "Português", "Ciências", "História", "Geografia"]
    private let bimestres = ["1º Bimestre", "2º Bimestre", "3º Bimestre", "4º Bimestre"]

    private var filtrados: [NotaAluno] {
        alunos.filter { searchText.isEmpty || $0.nome.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        selectorRow
                        turmaStats
                        if showChart { chartSection }
                        searchBar
                        notasList
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                if showSavedBanner {
                    savedBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(10)
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottom) { saveBar }
        }
    }

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Acadêmico",
            title: "Lançamento de Notas",
            subtitle: "1º Ano A · \(alunos.count) alunos"
        ) {
            Button {
                withAnimation(.spring(duration: 0.35)) { showChart.toggle() }
            } label: {
                Image(systemName: showChart ? "chart.bar.fill" : "chart.bar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SchoolPalette.primary)
                    .padding(10)
                    .background(SchoolPalette.primary.opacity(0.1), in: Circle())
            }
        }
        .padding(.top, 24)
    }

    private var selectorRow: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(disciplinas, id: \.self) { disc in
                    Button(disc) { selectedDisciplina = disc }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedDisciplina)
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(SchoolPalette.primary.opacity(0.1), in: Capsule())
            }

            Menu {
                ForEach(bimestres, id: \.self) { bim in
                    Button(bim) { selectedBimestre = bim }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedBimestre)
                    Image(systemName: "chevron.down")
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.violet)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(SchoolPalette.violet.opacity(0.1), in: Capsule())
            }
            Spacer()
        }
    }

    private var turmaStats: some View {
        HStack(spacing: 10) {
            let aprovados = alunos.filter { $0.situacao == "Aprovado" }.count
            let recuperacao = alunos.filter { $0.situacao == "Recuperação" }.count
            let reprovados = alunos.filter { $0.situacao == "Reprovado" }.count
            let semNota = alunos.filter { $0.media == nil }.count

            statMini(value: "\(aprovados)", label: "Aprovados", color: SchoolPalette.success)
            statMini(value: "\(recuperacao)", label: "Recuperação", color: SchoolPalette.warning)
            statMini(value: "\(reprovados)", label: "Reprovados", color: SchoolPalette.danger)
            statMini(value: "\(semNota)", label: "Sem nota", color: SchoolPalette.secondaryText)
        }
    }

    private func statMini(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }

    private var chartSection: some View {
        SchoolCard(title: "Distribuição de Notas") {
            Chart {
                ForEach(alunos.compactMap { a -> (String, Double)? in
                    guard let m = a.media else { return nil }
                    return (String(a.nome.split(separator: " ").first ?? ""), m)
                }, id: \.0) { item in
                    BarMark(
                        x: .value("Aluno", item.0),
                        y: .value("Nota", item.1)
                    )
                    .foregroundStyle(item.1 >= 7 ? SchoolPalette.success : item.1 >= 5 ? SchoolPalette.warning : SchoolPalette.danger)
                    .cornerRadius(6)
                }
                RuleMark(y: .value("Mínima", 7.0))
                    .foregroundStyle(SchoolPalette.primary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("7.0")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.primary)
                    }
            }
            .frame(height: 160)
            .chartYScale(domain: 0...10)
        }
    }

    private var searchBar: some View {
        SchoolSearchBar(text: $searchText, placeholder: "Buscar aluno...")
    }

    private var notasList: some View {
        LazyVStack(spacing: 10) {
            ForEach(filtrados.indices, id: \.self) { idx in
                if let globalIdx = alunos.firstIndex(where: { $0.id == filtrados[idx].id }) {
                    NotaAlunoRow(aluno: $alunos[globalIdx])
                }
            }
        }
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                salvarNotas()
            } label: {
                HStack(spacing: 8) {
                    if isSaving { ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.8) }
                    Text(isSaving ? "Salvando..." : "Salvar Notas")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(SchoolPalette.primary, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
            }
            .disabled(isSaving)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
    }

    private var savedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(SchoolPalette.success)
            Text("Notas salvas com sucesso!")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20).padding(.top, 60)
    }

    private func salvarNotas() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isSaving = false
            withAnimation(.spring(duration: 0.4)) { showSavedBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showSavedBanner = false }
            }
        }
    }
}

// MARK: - NotaAlunoRow

struct NotaAlunoRow: View {
    @Binding var aluno: NotaAluno
    @State private var isExpanded = false

    var body: some View {
        SchoolCard {
            VStack(spacing: 14) {
                Button {
                    withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 12) {
                        InitialAvatar(name: aluno.nome, accent: aluno.accent, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(aluno.nome)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            if let media = aluno.media {
                                Text(String(format: "Média: %.1f", media))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(aluno.situacaoColor)
                            } else {
                                Text("Sem notas lançadas")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)
                            }
                        }
                        Spacer()
                        StatusChip(text: aluno.situacao, color: aluno.situacaoColor)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SchoolPalette.secondaryText)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()
                    VStack(spacing: 10) {
                        notaField("AV1 (0–10)", value: $aluno.av1)
                        notaField("AV2 (0–10)", value: $aluno.av2)
                        notaField("AV3 (0–10)", value: $aluno.av3)
                        if aluno.situacao == "Recuperação" {
                            notaField("Recuperação (0–10)", value: $aluno.recuperacao)
                        }
                    }
                }
            }
        }
    }

    private func notaField(_ label: String, value: Binding<Double?>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            Spacer()
            TextField("—", value: value, format: .number.precision(.fractionLength(1)))
                .textFieldStyle(.plain)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
                .frame(width: 60)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(SchoolPalette.background, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(SchoolPalette.outline))
        }
    }
}

// MARK: - Demo Data

extension NotaAluno {
    static let demo: [NotaAluno] = [
        NotaAluno(id: "na-1", nome: "Sophia Anderson", accent: SchoolPalette.primary, av1: 9.5, av2: 8.8, av3: 9.2),
        NotaAluno(id: "na-2", nome: "Elena Rodriguez", accent: SchoolPalette.violet, av1: 8.0, av2: 7.5, av3: 8.5),
        NotaAluno(id: "na-3", nome: "Jordan Lee", accent: SchoolPalette.warning, av1: 5.5, av2: 6.0, av3: nil),
        NotaAluno(id: "na-4", nome: "Gabriel Souza", accent: SchoolPalette.success, av1: 4.0, av2: 3.5, av3: 4.5),
        NotaAluno(id: "na-5", nome: "Isabella Martins", accent: SchoolPalette.danger, av1: nil, av2: nil, av3: nil),
        NotaAluno(id: "na-6", nome: "Lucas Ferreira", accent: SchoolPalette.primary, av1: 7.0, av2: 7.5, av3: 8.0)
    ]
}

#Preview {
    NotasLancamentoView()
}
