// LS-36: Implementar cadastro e vínculo de responsáveis
import SwiftUI

// MARK: - Guardian DTO

struct GuardianDTO: Codable, Identifiable {
    let id: String
    let studentId: String
    let name: String
    let relationship: String
    let phone: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case id, name, relationship, phone, email
        case studentId = "student_id"
    }

    func toGuardian() -> Guardian {
        Guardian(id: id, name: name, relationship: relationship, phone: phone, email: email)
    }
}

// MARK: - Guardian Service

@MainActor
final class GuardianService: ObservableObject {
    static let shared = GuardianService()
    private let supabase = SupabaseService.shared
    private let sync = SyncService.shared

    @Published private(set) var guardians: [Guardian] = []
    @Published private(set) var isLoading = false

    private init() {}

    func fetchGuardians(forStudentId studentId: String) async {
        isLoading = true
        do {
            let queryItems = [URLQueryItem(name: "student_id", value: "eq.\(studentId)")]
            let dtos: [GuardianDTO] = try await supabase.fetch(from: "guardians", queryItems: queryItems)
            guardians = dtos.map { $0.toGuardian() }
            await sync.cacheGuardians(guardians, forStudentId: studentId)
        } catch {
            // Fall back to cache
            guardians = await sync.loadCachedGuardians(forStudentId: studentId)
        }
        isLoading = false
    }

    func addGuardian(_ dto: GuardianDTO) async throws {
        _ = try await supabase.insert(into: "guardians", value: dto)
        await fetchGuardians(forStudentId: dto.studentId)
    }

    func updateGuardian(_ dto: GuardianDTO) async throws {
        _ = try await supabase.update(table: "guardians", id: dto.id, value: dto)
        await fetchGuardians(forStudentId: dto.studentId)
    }

    func removeGuardian(id: String, studentId: String) async throws {
        try await supabase.delete(from: "guardians", id: id)
        guardians.removeAll { $0.id == id }
        await sync.cacheGuardians(guardians, forStudentId: studentId)
    }
}

// MARK: - Responsável Form View

struct ResponsavelFormView: View {
    let studentId: String
    let studentName: String
    let guardian: Guardian?
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var service = GuardianService.shared

    @State private var name: String
    @State private var relationship: String
    @State private var phone: String
    @State private var email: String

    @State private var isSaving = false
    @State private var validationError: String?

    private let relationships = ["Pai", "Mãe", "Avô", "Avó", "Tio", "Tia", "Responsável Legal", "Outro"]

    init(studentId: String, studentName: String, guardian: Guardian?, onSaved: @escaping () -> Void) {
        self.studentId = studentId
        self.studentName = studentName
        self.guardian = guardian
        self.onSaved = onSaved
        _name = State(initialValue: guardian?.name ?? "")
        _relationship = State(initialValue: guardian?.relationship ?? "Pai")
        _phone = State(initialValue: guardian?.phone ?? "")
        _email = State(initialValue: guardian?.email ?? "")
    }

    private var isEditing: Bool { guardian != nil }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !phone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Student context banner
                    SchoolCard {
                        HStack(spacing: 14) {
                            InitialAvatar(name: studentName, accent: SchoolPalette.primary, size: 44)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Vinculando responsável a")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)
                                Text(studentName)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.primaryText)
                            }
                        }
                    }

                    // Form fields
                    SchoolCard(title: "Dados do Responsável") {
                        VStack(spacing: 16) {
                            FormField(label: "Nome completo", placeholder: "Ex.: Roberto Mendes", value: $name)
                            FormPicker(label: "Parentesco / Vínculo", value: $relationship, options: relationships)
                            FormField(label: "Telefone / WhatsApp", placeholder: "+55 (11) 98765-4321", value: $phone, keyboard: .phonePad)
                            FormField(label: "E-mail", placeholder: "responsavel@email.com", value: $email, keyboard: .emailAddress)
                        }
                    }

                    if let error = validationError {
                        ErrorBanner(message: error) { validationError = nil }
                    }
                }
                .padding(24)
            }
            .navigationTitle(isEditing ? "Editar Responsável" : "Novo Responsável")
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
            validationError = "Nome e telefone são obrigatórios."
            return
        }

        isSaving = true
        validationError = nil

        let dto = GuardianDTO(
            id: guardian?.id ?? UUID().uuidString,
            studentId: studentId,
            name: name.trimmingCharacters(in: .whitespaces),
            relationship: relationship,
            phone: phone.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces)
        )

        do {
            if isEditing {
                try await service.updateGuardian(dto)
            } else {
                try await service.addGuardian(dto)
            }
            onSaved()
            dismiss()
        } catch {
            validationError = error.localizedDescription
        }

        isSaving = false
    }
}

// MARK: - Guardians Panel (embedded in student detail)

struct GuardiansPanelView: View {
    let studentId: String
    let studentName: String

    @StateObject private var service = GuardianService.shared
    @State private var isPresentingForm = false
    @State private var selectedGuardian: Guardian?
    @State private var deleteTarget: Guardian?
    @State private var showDeleteConfirm = false
    @State private var actionError: String?

    var body: some View {
        SchoolCard(title: "Responsáveis", subtitle: "\(service.guardians.count) vínculo(s)") {
            VStack(spacing: 12) {
                if service.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if service.guardians.isEmpty {
                    Text("Nenhum responsável vinculado.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                } else {
                    ForEach(service.guardians) { guardian in
                        GuardianRow(guardian: guardian) {
                            selectedGuardian = guardian
                            isPresentingForm = true
                        } onDelete: {
                            deleteTarget = guardian
                            showDeleteConfirm = true
                        }

                        if guardian.id != service.guardians.last?.id {
                            Divider()
                        }
                    }
                }

                if let error = actionError {
                    ErrorBanner(message: error) { actionError = nil }
                }

                Button {
                    selectedGuardian = nil
                    isPresentingForm = true
                } label: {
                    Label("Adicionar Responsável", systemImage: "person.fill.badge.plus")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(SchoolPalette.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .task { await service.fetchGuardians(forStudentId: studentId) }
        .sheet(isPresented: $isPresentingForm) {
            ResponsavelFormView(
                studentId: studentId,
                studentName: studentName,
                guardian: selectedGuardian
            ) {
                Task { await service.fetchGuardians(forStudentId: studentId) }
            }
        }
        .confirmationDialog(
            "Remover responsável",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Remover \(deleteTarget?.name ?? "")", role: .destructive) {
                Task { await performDelete() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("O vínculo com o aluno será desfeito.")
        }
    }

    private func performDelete() async {
        guard let target = deleteTarget else { return }
        do {
            try await service.removeGuardian(id: target.id, studentId: studentId)
        } catch {
            actionError = error.localizedDescription
        }
        deleteTarget = nil
    }
}

private struct GuardianRow: View {
    let guardian: Guardian
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            InitialAvatar(name: guardian.name, accent: SchoolPalette.violet, size: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(guardian.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)
                Text(guardian.relationship)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SchoolPalette.violet)
                Text(guardian.phone)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
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
                    .font(.system(size: 18))
                    .foregroundStyle(SchoolPalette.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}
