import SwiftUI

// MARK: - Models

struct Turma: Identifiable {
    let id: String
    let nome: String
    let serie: String
    let turno: String
    let disciplinas: [Disciplina]
    let capacidade: Int
    let matriculados: Int
    let professor: String
    let sala: String
    let accent: Color
    let status: String
}

struct Disciplina: Identifiable {
    let id: String
    let nome: String
    let cargaHoraria: Int
    let professor: String
    let accent: Color
}

// MARK: - Demo Data

extension Turma {
    static let demoData: [Turma] = [
        Turma(
            id: "t-1",
            nome: "1º Ano A",
            serie: "1º Ano",
            turno: "Manhã",
            disciplinas: Disciplina.demo,
            capacidade: 30,
            matriculados: 28,
            professor: "Dr. Sarah Jenkins",
            sala: "Sala 101",
            accent: SchoolPalette.primary,
            status: "Ativa"
        ),
        Turma(
            id: "t-2",
            nome: "2º Ano B",
            serie: "2º Ano",
            turno: "Tarde",
            disciplinas: Disciplina.demo,
            capacidade: 35,
            matriculados: 35,
            professor: "Prof. Marcus Chen",
            sala: "Sala 205",
            accent: SchoolPalette.violet,
            status: "Lotada"
        ),
        Turma(
            id: "t-3",
            nome: "3º Ano C",
            serie: "3º Ano",
            turno: "Manhã",
            disciplinas: Disciplina.demo,
            capacidade: 30,
            matriculados: 22,
            professor: "Dr. Alan Turing",
            sala: "Sala 310",
            accent: SchoolPalette.success,
            status: "Ativa"
        ),
        Turma(
            id: "t-4",
            nome: "4º Ano A",
            serie: "4º Ano",
            turno: "Tarde",
            disciplinas: [],
            capacidade: 30,
            matriculados: 0,
            professor: "—",
            sala: "A definir",
            accent: SchoolPalette.warning,
            status: "Planejada"
        )
    ]
}

extension Disciplina {
    static let demo: [Disciplina] = [
        Disciplina(id: "d-1", nome: "Matemática", cargaHoraria: 80, professor: "Dr. Sarah Jenkins", accent: SchoolPalette.primary),
        Disciplina(id: "d-2", nome: "Português", cargaHoraria: 80, professor: "Dr. Alan Turing", accent: SchoolPalette.violet),
        Disciplina(id: "d-3", nome: "Ciências", cargaHoraria: 60, professor: "Prof. Marcus Chen", accent: SchoolPalette.success),
        Disciplina(id: "d-4", nome: "História", cargaHoraria: 40, professor: "Dr. Alan Turing", accent: SchoolPalette.warning),
        Disciplina(id: "d-5", nome: "Geografia", cargaHoraria: 40, professor: "Prof. Marcus Chen", accent: SchoolPalette.danger)
    ]
}

// MARK: - TurmasListView

struct TurmasListView: View {
    @State private var searchText = ""
    @State private var selectedTurno = "Todos"
    @State private var showForm = false
    @State private var selectedTurma: Turma?

    private let turnos = ["Todos", "Manhã", "Tarde", "Noite"]

    private var filtered: [Turma] {
        Turma.demoData.filter { turma in
            let matchSearch = searchText.isEmpty || turma.nome.localizedCaseInsensitiveContains(searchText) || turma.professor.localizedCaseInsensitiveContains(searchText)
            let matchTurno = selectedTurno == "Todos" || turma.turno == selectedTurno
            return matchSearch && matchTurno
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        filterRow
                        turmasList
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showForm) {
                TurmaFormView(turma: nil)
            }
            .sheet(item: $selectedTurma) { turma in
                TurmaFormView(turma: turma)
            }
        }
    }

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Acadêmico",
            title: "Turmas",
            subtitle: "\(Turma.demoData.count) turmas · \(Turma.demoData.filter { $0.status == "Ativa" }.count) ativas"
        ) {
            Button {
                showForm = true
            } label: {
                Label("Nova Turma", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(SchoolPalette.primary, in: Capsule())
            }
        }
        .padding(.top, 24)
    }

    private var filterRow: some View {
        VStack(spacing: 12) {
            SchoolSearchBar(text: $searchText, placeholder: "Buscar turma ou professor...")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(turnos, id: \.self) { turno in
                        Button {
                            selectedTurno = turno
                        } label: {
                            Text(turno)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(selectedTurno == turno ? .white : SchoolPalette.secondaryText)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedTurno == turno ? SchoolPalette.primary : SchoolPalette.surface,
                                    in: Capsule()
                                )
                        }
                    }
                }
            }
        }
    }

    private var turmasList: some View {
        LazyVStack(spacing: 16) {
            ForEach(filtered) { turma in
                TurmaCard(turma: turma)
                    .onTapGesture { selectedTurma = turma }
            }
        }
    }
}

// MARK: - TurmaCard

struct TurmaCard: View {
    let turma: Turma

    private var ocupacaoPercent: Double {
        guard turma.capacidade > 0 else { return 0 }
        return Double(turma.matriculados) / Double(turma.capacidade)
    }

    private var statusColor: Color {
        switch turma.status {
        case "Ativa": return SchoolPalette.success
        case "Lotada": return SchoolPalette.danger
        case "Planejada": return SchoolPalette.warning
        default: return SchoolPalette.secondaryText
        }
    }

    var body: some View {
        SchoolCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(turma.accent.opacity(0.12))
                        .frame(width: 52, height: 52)
                        .overlay {
                            Text(turma.nome.prefix(2))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(turma.accent)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(turma.nome)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.primaryText)
                        Text(turma.turno + " · " + turma.sala)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(SchoolPalette.secondaryText)
                    }
                    Spacer()
                    StatusChip(text: turma.status, color: statusColor)
                }

                HStack(spacing: 20) {
                    infoItem(icon: "person.fill", label: turma.professor)
                    Spacer()
                    infoItem(icon: "book.closed.fill", label: "\(turma.disciplinas.count) disciplinas")
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Ocupação")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(SchoolPalette.secondaryText)
                        Spacer()
                        Text("\(turma.matriculados)/\(turma.capacidade)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.primaryText)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(SchoolPalette.outline)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(turma.accent)
                                .frame(width: geo.size.width * ocupacaoPercent, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                if !turma.disciplinas.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(turma.disciplinas) { disc in
                                Text(disc.nome)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(disc.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(disc.accent.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }
            }
        }
    }

    private func infoItem(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SchoolPalette.secondaryText)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
                .lineLimit(1)
        }
    }
}

#Preview {
    TurmasListView()
}
