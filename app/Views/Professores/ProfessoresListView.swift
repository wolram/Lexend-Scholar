// LS-53: Implementar CRUD de professores
import SwiftUI

struct ProfessoresListView: View {
    @StateObject private var service = AcademicService.shared
    @State private var searchText = ""
    @State private var isPresentingForm = false
    @State private var selectedTeacher: Teacher?
    @State private var deleteTarget: Teacher?
    @State private var showDeleteConfirm = false
    @State private var actionError: String?

    private var filtered: [Teacher] {
        guard !searchText.isEmpty else { return service.teachers }
        return service.teachers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.department.localizedCaseInsensitiveContains(searchText) ||
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                SchoolSectionHeader(
                    eyebrow: "Cadastro",
                    title: "Professores",
                    subtitle: "\(service.teachers.count) docentes ativos"
                ) {
                    Button {
                        selectedTeacher = nil
                        isPresentingForm = true
                    } label: {
                        Label("Novo Professor", systemImage: "person.fill.badge.plus")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .schoolProminentButton()
                }

                SchoolSearchBar(text: $searchText, placeholder: "Buscar por nome, área ou cargo...")

                if let error = actionError {
                    ErrorBanner(message: error) { actionError = nil }
                }

                if service.isLoadingTeachers {
                    ProgressView("Carregando professores...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else if filtered.isEmpty {
                    EmptyStateView(
                        symbol: "person.text.rectangle",
                        title: searchText.isEmpty ? "Nenhum professor cadastrado" : "Nenhum resultado",
                        subtitle: searchText.isEmpty
                            ? "Toque em "Novo Professor" para cadastrar o primeiro docente."
                            : "Tente ajustar os termos da busca."
                    )
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 320), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(filtered) { teacher in
                            TeacherRowCard(teacher: teacher) {
                                selectedTeacher = teacher
                                isPresentingForm = true
                            } onDelete: {
                                deleteTarget = teacher
                                showDeleteConfirm = true
                            }
                        }
                    }
                }
            }
            .padding(32)
        }
        .task { await service.fetchTeachers() }
        .sheet(isPresented: $isPresentingForm) {
            ProfessorFormView(teacher: selectedTeacher) {
                Task { await service.fetchTeachers() }
            }
        }
        .confirmationDialog(
            "Remover professor",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remover \(deleteTarget?.name ?? "")", role: .destructive) {
                Task { await performDelete() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
    }

    private func performDelete() async {
        guard let target = deleteTarget else { return }
        do {
            try await service.deleteTeacher(id: target.id)
        } catch {
            actionError = error.localizedDescription
        }
        deleteTarget = nil
    }
}

// MARK: - Teacher Row Card

private struct TeacherRowCard: View {
    let teacher: Teacher
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SchoolCard {
            HStack(spacing: 16) {
                InitialAvatar(name: teacher.name, accent: teacher.accent, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(teacher.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)

                    Text(teacher.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        Label("\(teacher.activeCourses) turmas", systemImage: "book.closed")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(teacher.accent)

                        Label("\(teacher.advisees) orientandos", systemImage: "person.2")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(SchoolPalette.secondaryText)
                    }
                }

                Spacer(minLength: 0)

                Menu {
                    Button { onEdit() } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button(role: .destructive) { onDelete() } label: {
                        Label("Remover", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(SchoolPalette.secondaryText)
                }
            }

            if !teacher.expertise.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(teacher.expertise, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(teacher.accent)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(teacher.accent.opacity(0.1), in: Capsule())
                        }
                    }
                }
            }
        }
    }
}
