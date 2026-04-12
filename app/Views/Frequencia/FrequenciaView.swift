import SwiftUI

// MARK: - Models

struct FrequenciaAluno: Identifiable {
    let id: String
    let nome: String
    let accent: Color
    var estado: AttendanceState
}

struct FrequenciaSessao: Identifiable {
    let id: String
    let turma: String
    let disciplina: String
    let data: Date
    var registros: [FrequenciaAluno]

    var presentes: Int { registros.filter { $0.estado == .present }.count }
    var ausentes: Int { registros.filter { $0.estado == .absent }.count }
    var atrasados: Int { registros.filter { $0.estado == .late }.count }
    var taxaPresenca: Double {
        guard !registros.isEmpty else { return 0 }
        return Double(presentes) / Double(registros.count) * 100
    }
}

// MARK: - FrequenciaView

struct FrequenciaView: View {
    @State private var sessao: FrequenciaSessao = .demo
    @State private var searchText = ""
    @State private var filtroEstado: AttendanceState? = nil
    @State private var isSaving = false
    @State private var showSavedBanner = false

    private var filtrados: [FrequenciaAluno] {
        sessao.registros.filter { aluno in
            let matchBusca = searchText.isEmpty || aluno.nome.localizedCaseInsensitiveContains(searchText)
            let matchFiltro = filtroEstado == nil || aluno.estado == filtroEstado
            return matchBusca && matchFiltro
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                SchoolCanvasBackground()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            headerSection
                            statsBar
                            filterControls
                            alunosList
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
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
            title: "Frequência",
            subtitle: sessao.turma + " · " + sessao.disciplina
        ) {
            Text(sessao.data, style: .date)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(SchoolPalette.primary.opacity(0.1), in: Capsule())
        }
        .padding(.top, 24)
    }

    private var statsBar: some View {
        HStack(spacing: 10) {
            statPill(value: "\(sessao.presentes)", label: "Presentes", color: SchoolPalette.primary)
            statPill(value: "\(sessao.ausentes)", label: "Ausentes", color: SchoolPalette.danger)
            statPill(value: "\(sessao.atrasados)", label: "Atrasados", color: SchoolPalette.warning)
            statPill(value: String(format: "%.0f%%", sessao.taxaPresenca), label: "Taxa", color: SchoolPalette.success)
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
    }

    private var filterControls: some View {
        VStack(spacing: 10) {
            SchoolSearchBar(text: $searchText, placeholder: "Buscar aluno...")
            HStack(spacing: 8) {
                filterChip(label: "Todos", color: SchoolPalette.secondaryText, isSelected: filtroEstado == nil) {
                    filtroEstado = nil
                }
                filterChip(label: "Presente", color: SchoolPalette.primary, isSelected: filtroEstado == .present) {
                    filtroEstado = filtroEstado == .present ? nil : .present
                }
                filterChip(label: "Ausente", color: SchoolPalette.danger, isSelected: filtroEstado == .absent) {
                    filtroEstado = filtroEstado == .absent ? nil : .absent
                }
                filterChip(label: "Atrasado", color: SchoolPalette.warning, isSelected: filtroEstado == .late) {
                    filtroEstado = filtroEstado == .late ? nil : .late
                }
            }
        }
    }

    private func filterChip(label: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? color : color.opacity(0.1), in: Capsule())
        }
    }

    private var alunosList: some View {
        LazyVStack(spacing: 10) {
            ForEach(filtrados.indices, id: \.self) { idx in
                if let globalIdx = sessao.registros.firstIndex(where: { $0.id == filtrados[idx].id }) {
                    FrequenciaAlunoRow(aluno: $sessao.registros[globalIdx])
                }
            }
        }
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    marcarTodos(.present)
                } label: {
                    Text("Todos Presentes")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(SchoolPalette.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    salvarFrequencia()
                } label: {
                    HStack(spacing: 8) {
                        if isSaving { ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.8) }
                        Text(isSaving ? "Salvando..." : "Salvar Registro")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(SchoolPalette.primary, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
        }
    }

    private var savedBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(SchoolPalette.success)
            Text("Frequência salva com sucesso!")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }

    private func marcarTodos(_ estado: AttendanceState) {
        for i in sessao.registros.indices {
            sessao.registros[i].estado = estado
        }
    }

    private func salvarFrequencia() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isSaving = false
            withAnimation(.spring(duration: 0.4)) {
                showSavedBanner = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation { showSavedBanner = false }
            }
        }
    }
}

// MARK: - FrequenciaAlunoRow

struct FrequenciaAlunoRow: View {
    @Binding var aluno: FrequenciaAluno

    var body: some View {
        HStack(spacing: 14) {
            InitialAvatar(name: aluno.nome, accent: aluno.accent, size: 44)
            Text(aluno.nome)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
            Spacer()
            HStack(spacing: 6) {
                attendanceButton(.present, icon: "checkmark", color: SchoolPalette.primary)
                attendanceButton(.late, icon: "clock.fill", color: SchoolPalette.warning)
                attendanceButton(.absent, icon: "xmark", color: SchoolPalette.danger)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(aluno.estado.color.opacity(0.3), lineWidth: 1.5)
        )
        .animation(.spring(duration: 0.25), value: aluno.estado)
    }

    private func attendanceButton(_ estado: AttendanceState, icon: String, color: Color) -> some View {
        Button {
            aluno.estado = estado
        } label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(aluno.estado == estado ? .white : color)
                .frame(width: 32, height: 32)
                .background(aluno.estado == estado ? color : color.opacity(0.1), in: Circle())
        }
    }
}

// MARK: - Demo Data

extension FrequenciaSessao {
    static let demo = FrequenciaSessao(
        id: "fs-1",
        turma: "1º Ano A",
        disciplina: "Matemática",
        data: Date(),
        registros: [
            FrequenciaAluno(id: "fa-1", nome: "Sophia Anderson", accent: SchoolPalette.primary, estado: .present),
            FrequenciaAluno(id: "fa-2", nome: "Elena Rodriguez", accent: SchoolPalette.violet, estado: .present),
            FrequenciaAluno(id: "fa-3", nome: "Jordan Lee", accent: SchoolPalette.warning, estado: .late),
            FrequenciaAluno(id: "fa-4", nome: "Gabriel Souza", accent: SchoolPalette.success, estado: .absent),
            FrequenciaAluno(id: "fa-5", nome: "Isabella Martins", accent: SchoolPalette.danger, estado: .present),
            FrequenciaAluno(id: "fa-6", nome: "Lucas Ferreira", accent: SchoolPalette.primary, estado: .present),
            FrequenciaAluno(id: "fa-7", nome: "Ana Clara Silva", accent: SchoolPalette.violet, estado: .present),
            FrequenciaAluno(id: "fa-8", nome: "Pedro Almeida", accent: SchoolPalette.warning, estado: .present)
        ]
    )
}

#Preview {
    FrequenciaView()
}
