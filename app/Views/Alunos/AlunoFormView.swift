// LS-52: Implementar CRUD de alunos conectado ao Supabase
import SwiftUI

struct AlunoFormView: View {
    let student: Student?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = AcademicService.shared

    // Form fields
    @State private var name: String
    @State private var grade: String
    @State private var studentNumber: String
    @State private var department: String
    @State private var status: String
    @State private var bio: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var gpa: String
    @State private var attendance: String
    @State private var rankLabel: String
    @State private var credits: String
    @State private var advisor: String

    @State private var isSaving = false
    @State private var validationError: String?

    private let departments = ["STEM", "Ciências", "Humanidades", "Tecnologia", "Artes"]
    private let statuses = ["Ativo", "Suporte", "Inativo"]

    init(student: Student?, onSaved: @escaping () -> Void) {
        self.student = student
        self.onSaved = onSaved
        _name = State(initialValue: student?.name ?? "")
        _grade = State(initialValue: student?.grade ?? "")
        _studentNumber = State(initialValue: student?.studentNumber ?? "")
        _department = State(initialValue: student?.department ?? "STEM")
        _status = State(initialValue: student?.status ?? "Ativo")
        _bio = State(initialValue: student?.bio ?? "")
        _email = State(initialValue: student?.email ?? "")
        _phone = State(initialValue: student?.phone ?? "")
        _address = State(initialValue: student?.address ?? "")
        _gpa = State(initialValue: student.map { String(format: "%.1f", $0.gpa) } ?? "")
        _attendance = State(initialValue: student.map { String($0.attendance) } ?? "")
        _rankLabel = State(initialValue: student?.rank ?? "")
        _credits = State(initialValue: student.map { String($0.credits) } ?? "")
        _advisor = State(initialValue: student?.advisor ?? "")
    }

    private var isEditing: Bool { student != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Identity section
                    SchoolCard(title: "Identificação") {
                        VStack(spacing: 16) {
                            FormField(label: "Nome completo", placeholder: "Ex.: Ana Carolina Silva", value: $name)
                            FormField(label: "Número de matrícula", placeholder: "#STU-2024-001", value: $studentNumber)
                            FormField(label: "Turma", placeholder: "Ex.: Grade 10-A", value: $grade)

                            FormPicker(label: "Área", value: $department, options: departments)
                            FormPicker(label: "Status", value: $status, options: statuses)
                        }
                    }

                    // Contact section
                    SchoolCard(title: "Contato") {
                        VStack(spacing: 16) {
                            FormField(label: "E-mail", placeholder: "aluno@escola.edu.br", value: $email, keyboard: .emailAddress)
                            FormField(label: "Telefone", placeholder: "+55 (11) 99999-9999", value: $phone, keyboard: .phonePad)
                            FormField(label: "Endereço", placeholder: "Rua, número, cidade", value: $address)
                        }
                    }

                    // Academic section
                    SchoolCard(title: "Dados Acadêmicos") {
                        VStack(spacing: 16) {
                            FormField(label: "GPA", placeholder: "3.8", value: $gpa, keyboard: .decimalPad)
                            FormField(label: "Frequência (%)", placeholder: "98", value: $attendance, keyboard: .numberPad)
                            FormField(label: "Ranking", placeholder: "12 / 145", value: $rankLabel)
                            FormField(label: "Créditos", placeholder: "64.0", value: $credits, keyboard: .decimalPad)
                            FormField(label: "Orientador", placeholder: "Dr. Nome Sobrenome", value: $advisor)
                        }
                    }

                    // Bio section
                    SchoolCard(title: "Biografia") {
                        TextEditor(text: $bio)
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
            .navigationTitle(isEditing ? "Editar Aluno" : "Novo Aluno")
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

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !grade.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() async {
        guard isValid else {
            validationError = "Nome, e-mail e turma são obrigatórios."
            return
        }

        isSaving = true
        validationError = nil

        let dto = StudentDTO(
            id: student?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            grade: grade.trimmingCharacters(in: .whitespaces),
            studentNumber: studentNumber.trimmingCharacters(in: .whitespaces),
            department: department,
            status: status,
            bio: bio,
            email: email.trimmingCharacters(in: .whitespaces),
            phone: phone.trimmingCharacters(in: .whitespaces),
            address: address.trimmingCharacters(in: .whitespaces),
            gpa: Double(gpa) ?? 0.0,
            attendance: Int(attendance) ?? 0,
            rankLabel: rankLabel.trimmingCharacters(in: .whitespaces),
            credits: Double(credits) ?? 0.0,
            advisor: advisor.trimmingCharacters(in: .whitespaces)
        )

        do {
            if isEditing {
                try await service.updateStudent(dto)
            } else {
                try await service.createStudent(dto)
            }
            onSaved()
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }

        isSaving = false
    }
}

// MARK: - Reusable Form Components

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)

            TextField(placeholder, text: $value)
                .keyboardType(keyboard)
                .autocorrectionDisabled(keyboard != .default)
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
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
}

struct FormPicker: View {
    let label: String
    @Binding var value: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)

            Picker(label, selection: $value) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(SchoolPalette.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
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
}
