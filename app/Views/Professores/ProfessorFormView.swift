// LS-53: Implementar CRUD de professores
import SwiftUI

struct ProfessorFormView: View {
    let teacher: Teacher?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = AcademicService.shared

    @State private var name: String
    @State private var title: String
    @State private var department: String
    @State private var email: String
    @State private var office: String
    @State private var advisees: String
    @State private var activeCourses: String
    @State private var weeklyLoad: String
    @State private var summary: String
    @State private var expertiseRaw: String

    @State private var isSaving = false
    @State private var validationError: String?

    private let departments = ["Matemática", "Ciências", "Humanidades", "Tecnologia", "Artes", "Educação Física"]

    init(teacher: Teacher?, onSaved: @escaping () -> Void) {
        self.teacher = teacher
        self.onSaved = onSaved
        _name = State(initialValue: teacher?.name ?? "")
        _title = State(initialValue: teacher?.title ?? "")
        _department = State(initialValue: teacher?.department ?? "Matemática")
        _email = State(initialValue: teacher?.email ?? "")
        _office = State(initialValue: teacher?.office ?? "")
        _advisees = State(initialValue: teacher.map { String($0.advisees) } ?? "")
        _activeCourses = State(initialValue: teacher.map { String($0.activeCourses) } ?? "")
        _weeklyLoad = State(initialValue: teacher.map { String($0.weeklyLoad) } ?? "")
        _summary = State(initialValue: teacher?.summary ?? "")
        _expertiseRaw = State(initialValue: teacher?.expertise.joined(separator: ", ") ?? "")
    }

    private var isEditing: Bool { teacher != nil }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Identity
                    SchoolCard(title: "Identificação") {
                        VStack(spacing: 16) {
                            FormField(label: "Nome completo", placeholder: "Ex.: Prof. Ana Beatriz Souza", value: $name)
                            FormField(label: "Cargo / Título", placeholder: "Ex.: Professora Sênior de Ciências", value: $title)
                            FormPicker(label: "Departamento", value: $department, options: departments)
                        }
                    }

                    // Contact
                    SchoolCard(title: "Contato e Localização") {
                        VStack(spacing: 16) {
                            FormField(label: "E-mail institucional", placeholder: "prof@escola.edu.br", value: $email, keyboard: .emailAddress)
                            FormField(label: "Sala / Escritório", placeholder: "Bloco A, Sala 302", value: $office)
                        }
                    }

                    // Academic load
                    SchoolCard(title: "Carga Acadêmica") {
                        VStack(spacing: 16) {
                            FormField(label: "Turmas ativas", placeholder: "5", value: $activeCourses, keyboard: .numberPad)
                            FormField(label: "Orientandos", placeholder: "12", value: $advisees, keyboard: .numberPad)
                            FormField(label: "Carga semanal (horas)", placeholder: "20", value: $weeklyLoad, keyboard: .numberPad)
                        }
                    }

                    // Expertise
                    SchoolCard(title: "Áreas de Especialidade") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Separe as especialidades por vírgula")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)

                            TextField("Ex.: Álgebra, Geometria, Robótica", text: $expertiseRaw)
                                .textFieldStyle(.plain)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(SchoolPalette.background)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(SchoolPalette.outline, lineWidth: 1)
                                )
                        }
                    }

                    // Summary / Bio
                    SchoolCard(title: "Resumo Profissional") {
                        TextEditor(text: $summary)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 100)
                    }

                    if let error = validationError {
                        ErrorBanner(message: error) { validationError = nil }
                    }
                }
                .padding(24)
            }
            .navigationTitle(isEditing ? "Editar Professor" : "Novo Professor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        } else {
                            Text("Salvar")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                    }
                    .disabled(isSaving || !isValid)
                }
            }
        }
    }

    private func save() async {
        guard isValid else {
            validationError = "Nome e e-mail são obrigatórios."
            return
        }

        isSaving = true
        validationError = nil

        let dto = TeacherDTO(
            id: teacher?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            title: title.trimmingCharacters(in: .whitespaces),
            department: department,
            email: email.trimmingCharacters(in: .whitespaces),
            office: office.trimmingCharacters(in: .whitespaces),
            advisees: Int(advisees) ?? 0,
            activeCourses: Int(activeCourses) ?? 0,
            weeklyLoad: Int(weeklyLoad) ?? 0,
            summary: summary
        )

        do {
            if isEditing {
                try await service.updateTeacher(dto)
            } else {
                try await service.createTeacher(dto)
            }
            onSaved()
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }

        isSaving = false
    }
}
