import SwiftUI
import Charts

// MARK: - Models

struct BoletimDisciplina: Identifiable {
    let id: String
    let nome: String
    let professor: String
    let av1: Double
    let av2: Double
    let av3: Double
    let recuperacao: Double?
    let cargaHoraria: Int
    let faltas: Int
    let accent: Color

    var media: Double {
        let base = (av1 + av2 + av3) / 3
        if let rec = recuperacao { return (base + rec) / 2 }
        return base
    }

    var situacao: String {
        if media >= 7.0 { return "Aprovado" }
        if media >= 5.0 { return "Recuperação" }
        return "Reprovado"
    }

    var situacaoColor: Color {
        if media >= 7.0 { return SchoolPalette.success }
        if media >= 5.0 { return SchoolPalette.warning }
        return SchoolPalette.danger
    }

    var percentualFaltas: Double {
        guard cargaHoraria > 0 else { return 0 }
        return Double(faltas) / Double(cargaHoraria) * 100
    }
}

struct Boletim {
    let aluno: String
    let turma: String
    let periodo: String
    let anoLetivo: String
    let disciplinas: [BoletimDisciplina]

    var mediaGeral: Double {
        guard !disciplinas.isEmpty else { return 0 }
        return disciplinas.map { $0.media }.reduce(0, +) / Double(disciplinas.count)
    }

    var aprovadas: Int { disciplinas.filter { $0.situacao == "Aprovado" }.count }
    var emRecuperacao: Int { disciplinas.filter { $0.situacao == "Recuperação" }.count }
    var reprovadas: Int { disciplinas.filter { $0.situacao == "Reprovado" }.count }
}

// MARK: - BoletimView

struct BoletimView: View {
    @State private var boletim: Boletim = .demo
    @State private var selectedStudent = "Sophia Anderson"
    @State private var showingExport = false

    private let alunos = ["Sophia Anderson", "Elena Rodriguez", "Jordan Lee"]

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        studentSelector
                        mediaGeralCard
                        situacaoChart
                        disciplinasSection
                        footerInfo
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .confirmationDialog("Exportar Boletim", isPresented: $showingExport, titleVisibility: .visible) {
                Button("Exportar como PDF") {}
                Button("Compartilhar") {}
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Acadêmico",
            title: "Boletim",
            subtitle: boletim.periodo + " · " + boletim.anoLetivo
        ) {
            Button {
                showingExport = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(SchoolPalette.primary)
                    .padding(10)
                    .background(SchoolPalette.primary.opacity(0.1), in: Circle())
            }
        }
        .padding(.top, 24)
    }

    private var studentSelector: some View {
        Menu {
            ForEach(alunos, id: \.self) { aluno in
                Button(aluno) { selectedStudent = aluno }
            }
        } label: {
            HStack(spacing: 12) {
                InitialAvatar(name: selectedStudent, accent: SchoolPalette.primary, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedStudent)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                    Text(boletim.turma)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SchoolPalette.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(SchoolPalette.outline))
        }
    }

    private var mediaGeralCard: some View {
        SchoolCard {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Média Geral")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                    Text(String(format: "%.1f", boletim.mediaGeral))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(boletim.mediaGeral >= 7 ? SchoolPalette.success : boletim.mediaGeral >= 5 ? SchoolPalette.warning : SchoolPalette.danger)
                    StatusChip(
                        text: boletim.mediaGeral >= 7 ? "Aprovado" : "Em Risco",
                        color: boletim.mediaGeral >= 7 ? SchoolPalette.success : SchoolPalette.warning
                    )
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 10) {
                    summaryItem(value: "\(boletim.aprovadas)", label: "Aprovadas", color: SchoolPalette.success)
                    summaryItem(value: "\(boletim.emRecuperacao)", label: "Recuperação", color: SchoolPalette.warning)
                    summaryItem(value: "\(boletim.reprovadas)", label: "Reprovadas", color: SchoolPalette.danger)
                }
            }
        }
    }

    private func summaryItem(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .frame(minWidth: 24, alignment: .center)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color.opacity(0.1), in: Capsule())
        }
    }

    private var situacaoChart: some View {
        SchoolCard(title: "Desempenho por Disciplina") {
            Chart {
                ForEach(boletim.disciplinas) { disc in
                    BarMark(
                        x: .value("Disciplina", String(disc.nome.prefix(3))),
                        y: .value("Média", disc.media)
                    )
                    .foregroundStyle(disc.situacaoColor)
                    .cornerRadius(8)
                    .annotation(position: .top) {
                        Text(String(format: "%.1f", disc.media))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(disc.situacaoColor)
                    }
                }
                RuleMark(y: .value("Mínima", 7.0))
                    .foregroundStyle(SchoolPalette.primary.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
            }
            .frame(height: 160)
            .chartYScale(domain: 0...10)
        }
    }

    private var disciplinasSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Notas por Disciplina")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)

            ForEach(boletim.disciplinas) { disc in
                DisciplinaBoletimCard(disciplina: disc)
            }
        }
    }

    private var footerInfo: some View {
        SchoolCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Critérios de Aprovação", systemImage: "info.circle.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primary)
                Text("Média ≥ 7.0 · Aprovado  |  5.0 ≤ Média < 7.0 · Recuperação  |  Média < 5.0 · Reprovado")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                Text("Frequência mínima exigida: 75%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
            }
        }
    }
}

// MARK: - DisciplinaBoletimCard

struct DisciplinaBoletimCard: View {
    let disciplina: BoletimDisciplina
    @State private var isExpanded = false

    var body: some View {
        SchoolCard {
            VStack(spacing: 14) {
                Button {
                    withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
                } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(disciplina.accent.opacity(0.12))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Text(String(disciplina.nome.prefix(2)))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(disciplina.accent)
                            }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(disciplina.nome)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text(disciplina.professor)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(format: "%.1f", disciplina.media))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(disciplina.situacaoColor)
                            StatusChip(text: disciplina.situacao, color: disciplina.situacaoColor)
                        }
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SchoolPalette.secondaryText)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider()
                    HStack(spacing: 0) {
                        notaItem(label: "AV1", value: disciplina.av1)
                        notaItem(label: "AV2", value: disciplina.av2)
                        notaItem(label: "AV3", value: disciplina.av3)
                        if let rec = disciplina.recuperacao {
                            notaItem(label: "Rec", value: rec)
                        }
                    }
                    HStack {
                        Label("\(disciplina.faltas) faltas", systemImage: "calendar.badge.minus")
                        Spacer()
                        Text(String(format: "%.0f%% ausência", disciplina.percentualFaltas))
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(disciplina.percentualFaltas > 25 ? SchoolPalette.danger : SchoolPalette.secondaryText)
                }
            }
        }
    }

    private func notaItem(label: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            Text(String(format: "%.1f", value))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(value >= 7 ? SchoolPalette.success : value >= 5 ? SchoolPalette.warning : SchoolPalette.danger)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Demo Data

extension Boletim {
    static let demo = Boletim(
        aluno: "Sophia Anderson",
        turma: "1º Ano A",
        periodo: "1º Bimestre",
        anoLetivo: "2026",
        disciplinas: [
            BoletimDisciplina(id: "bd-1", nome: "Matemática", professor: "Dr. Sarah Jenkins", av1: 9.5, av2: 8.8, av3: 9.2, recuperacao: nil, cargaHoraria: 80, faltas: 2, accent: SchoolPalette.primary),
            BoletimDisciplina(id: "bd-2", nome: "Português", professor: "Dr. Alan Turing", av1: 8.0, av2: 7.5, av3: 8.5, recuperacao: nil, cargaHoraria: 80, faltas: 4, accent: SchoolPalette.violet),
            BoletimDisciplina(id: "bd-3", nome: "Ciências", professor: "Prof. Marcus Chen", av1: 5.5, av2: 6.0, av3: 5.0, recuperacao: 6.5, cargaHoraria: 60, faltas: 6, accent: SchoolPalette.success),
            BoletimDisciplina(id: "bd-4", nome: "História", professor: "Dr. Alan Turing", av1: 7.5, av2: 8.0, av3: 7.0, recuperacao: nil, cargaHoraria: 40, faltas: 0, accent: SchoolPalette.warning),
            BoletimDisciplina(id: "bd-5", nome: "Geografia", professor: "Prof. Marcus Chen", av1: 3.5, av2: 4.0, av3: 3.0, recuperacao: nil, cargaHoraria: 40, faltas: 12, accent: SchoolPalette.danger)
        ]
    )
}

#Preview {
    BoletimView()
}
