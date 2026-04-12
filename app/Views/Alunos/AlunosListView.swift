// LS-52: Implementar CRUD de alunos conectado ao Supabase
import SwiftUI

struct AlunosListView: View {
    @StateObject private var service = AcademicService.shared
    @State private var searchText = ""
    @State private var isPresentingForm = false
    @State private var selectedStudent: Student?
    @State private var deleteTarget: Student?
    @State private var showDeleteConfirm = false
    @State private var actionError: String?

    private var filtered: [Student] {
        guard !searchText.isEmpty else { return service.students }
        return service.students.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.grade.localizedCaseInsensitiveContains(searchText) ||
            $0.department.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                SchoolSectionHeader(
                    eyebrow: "Cadastro",
                    title: "Alunos",
                    subtitle: "\(service.students.count) alunos matriculados"
                ) {
                    Button {
                        selectedStudent = nil
                        isPresentingForm = true
                    } label: {
                        Label("Novo Aluno", systemImage: "person.badge.plus")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .schoolProminentButton()
                }

                SchoolSearchBar(text: $searchText, placeholder: "Buscar por nome, turma ou área...")

                if let error = actionError {
                    ErrorBanner(message: error) { actionError = nil }
                }

                if service.isLoadingStudents {
                    ProgressView("Carregando alunos...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else if filtered.isEmpty {
                    EmptyStateView(
                        symbol: "person.3",
                        title: searchText.isEmpty ? "Nenhum aluno cadastrado" : "Nenhum resultado",
                        subtitle: searchText.isEmpty
                            ? "Toque em "Novo Aluno" para cadastrar o primeiro aluno."
                            : "Tente ajustar os termos da busca."
                    )
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 320), spacing: 16)],
                        spacing: 16
                    ) {
                        ForEach(filtered) { student in
                            StudentRowCard(student: student) {
                                selectedStudent = student
                                isPresentingForm = true
                            } onDelete: {
                                deleteTarget = student
                                showDeleteConfirm = true
                            }
                        }
                    }
                }
            }
            .padding(32)
        }
        .task { await service.fetchStudents() }
        .sheet(isPresented: $isPresentingForm) {
            AlunoFormView(student: selectedStudent) {
                Task { await service.fetchStudents() }
            }
        }
        .confirmationDialog(
            "Remover aluno",
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
            try await service.deleteStudent(id: target.id)
        } catch {
            actionError = error.localizedDescription
        }
        deleteTarget = nil
    }
}

// MARK: - Student Row Card

private struct StudentRowCard: View {
    let student: Student
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        SchoolCard {
            HStack(spacing: 16) {
                InitialAvatar(name: student.name, accent: student.accent, size: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(student.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)

                    Text("\(student.grade) · \(student.department)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)

                    HStack(spacing: 8) {
                        StatusChip(text: student.status, color: chipColor(for: student.status))

                        Text("GPA \(String(format: "%.1f", student.gpa))")
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
        }
    }

    private func chipColor(for status: String) -> Color {
        switch status.lowercased() {
        case "active", "ativo": return SchoolPalette.success
        case "support", "suporte": return SchoolPalette.warning
        default: return SchoolPalette.secondaryText
        }
    }
}

// MARK: - Shared Helpers

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(SchoolPalette.secondaryText.opacity(0.5))
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }
}

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(SchoolPalette.danger)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button { onDismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(SchoolPalette.danger.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(SchoolPalette.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
