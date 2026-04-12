import SwiftUI

struct TurmaFormView: View {
    let turma: Turma?

    @Environment(\.dismiss) private var dismiss

    @State private var nome: String
    @State private var serie: String
    @State private var turno: String
    @State private var sala: String
    @State private var professor: String
    @State private var capacidade: String
    @State private var isSaving = false
    @State private var showSuccess = false

    private let series = ["1º Ano", "2º Ano", "3º Ano", "4º Ano", "5º Ano", "6º Ano", "7º Ano", "8º Ano", "9º Ano"]
    private let turnos = ["Manhã", "Tarde", "Noite"]
    private let professores = ["Dr. Sarah Jenkins", "Prof. Marcus Chen", "Dr. Alan Turing"]

    init(turma: Turma?) {
        self.turma = turma
        _nome = State(initialValue: turma?.nome ?? "")
        _serie = State(initialValue: turma?.serie ?? "1º Ano")
        _turno = State(initialValue: turma?.turno ?? "Manhã")
        _sala = State(initialValue: turma?.sala ?? "")
        _professor = State(initialValue: turma?.professor ?? "")
        _capacidade = State(initialValue: turma.map { String($0.capacidade) } ?? "30")
    }

    private var isEditing: Bool { turma != nil }
    private var isFormValid: Bool { !nome.trimmingCharacters(in: .whitespaces).isEmpty && !sala.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        formHeader
                        formFields
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var formHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SchoolPalette.secondaryText)
                        .padding(10)
                        .background(SchoolPalette.outline, in: Circle())
                }
                Spacer()
            }
            .padding(.top, 16)

            Text(isEditing ? "Editar Turma" : "Nova Turma")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
                .padding(.top, 8)

            Text(isEditing ? "Atualize as informações da turma." : "Preencha os dados para criar uma nova turma.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
        }
    }

    private var formFields: some View {
        VStack(spacing: 16) {
            SchoolCard(title: "Identificação") {
                VStack(spacing: 14) {
                    fieldLabel("Nome da Turma", placeholder: "Ex: 1º Ano A", text: $nome)
                    pickerField("Série", selection: $serie, options: series)
                    pickerField("Turno", selection: $turno, options: turnos)
                }
            }

            SchoolCard(title: "Estrutura") {
                VStack(spacing: 14) {
                    fieldLabel("Sala / Local", placeholder: "Ex: Sala 101", text: $sala)
                    fieldLabel("Capacidade de Alunos", placeholder: "30", text: $capacidade)
                        .keyboardType(.numberPad)
                    pickerField("Professor Responsável", selection: $professor, options: professores)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: showSuccess ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                }
                Text(isSaving ? "Salvando..." : showSuccess ? "Salvo!" : (isEditing ? "Salvar Alterações" : "Criar Turma"))
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isFormValid ? SchoolPalette.primary : SchoolPalette.outline, in: RoundedRectangle(cornerRadius: 18))
        }
        .disabled(!isFormValid || isSaving)
        .animation(.spring(duration: 0.3), value: isSaving)
    }

    private func fieldLabel(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(SchoolPalette.background, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(SchoolPalette.outline))
        }
    }

    private func pickerField(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            Picker(label, selection: selection) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.menu)
            .tint(SchoolPalette.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(SchoolPalette.background, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(SchoolPalette.outline))
        }
    }

    private func save() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isSaving = false
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        }
    }
}

#Preview {
    TurmaFormView(turma: nil)
}
