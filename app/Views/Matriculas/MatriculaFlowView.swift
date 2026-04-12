import SwiftUI

// MARK: - Models

enum MatriculaStep: Int, CaseIterable {
    case aluno = 0
    case turma = 1
    case responsavel = 2
    case documentos = 3
    case confirmacao = 4

    var titulo: String {
        switch self {
        case .aluno: return "Dados do Aluno"
        case .turma: return "Seleção de Turma"
        case .responsavel: return "Responsável"
        case .documentos: return "Documentos"
        case .confirmacao: return "Confirmação"
        }
    }

    var symbol: String {
        switch self {
        case .aluno: return "person.fill"
        case .turma: return "book.closed.fill"
        case .responsavel: return "person.2.fill"
        case .documentos: return "doc.fill"
        case .confirmacao: return "checkmark.seal.fill"
        }
    }
}

struct MatriculaRequest: Identifiable {
    let id: String
    let aluno: String
    let turma: String
    let status: String
    let data: String
    let accent: Color
}

// MARK: - MatriculaFlowView

struct MatriculaFlowView: View {
    @State private var currentStep: MatriculaStep = .aluno
    @State private var showNewFlow = false
    @State private var animatingStep = false

    private let pendentes: [MatriculaRequest] = [
        MatriculaRequest(id: "m-1", aluno: "Gabriel Souza", turma: "1º Ano A", status: "Pendente", data: "12/04/2026", accent: SchoolPalette.warning),
        MatriculaRequest(id: "m-2", aluno: "Isabella Martins", turma: "2º Ano B", status: "Em Análise", data: "10/04/2026", accent: SchoolPalette.primary),
        MatriculaRequest(id: "m-3", aluno: "Lucas Ferreira", turma: "3º Ano C", status: "Aprovada", data: "08/04/2026", accent: SchoolPalette.success)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        statsRow
                        pendingList
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNewFlow) {
                MatriculaWizardView()
            }
        }
    }

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Acadêmico",
            title: "Matrículas",
            subtitle: "Gerencie o fluxo de matrículas de alunos"
        ) {
            Button { showNewFlow = true } label: {
                Label("Nova Matrícula", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(SchoolPalette.primary, in: Capsule())
            }
        }
        .padding(.top, 24)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "3", label: "Pendentes", color: SchoolPalette.warning)
            statCard(value: "12", label: "Este Mês", color: SchoolPalette.primary)
            statCard(value: "248", label: "Total 2026", color: SchoolPalette.success)
        }
    }

    private func statCard(value: String, label: String, color: Color) -> some View {
        SchoolCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
            }
        }
    }

    private var pendingList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Solicitações Recentes")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)

            ForEach(pendentes) { req in
                MatriculaCard(request: req)
            }
        }
    }
}

// MARK: - MatriculaCard

struct MatriculaCard: View {
    let request: MatriculaRequest

    private var statusColor: Color {
        switch request.status {
        case "Aprovada": return SchoolPalette.success
        case "Em Análise": return SchoolPalette.primary
        default: return SchoolPalette.warning
        }
    }

    var body: some View {
        SchoolCard {
            HStack(spacing: 16) {
                InitialAvatar(name: request.aluno, accent: request.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.aluno)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                    Text(request.turma + " · " + request.data)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                }
                Spacer()
                StatusChip(text: request.status, color: statusColor)
            }
        }
    }
}

// MARK: - MatriculaWizardView

struct MatriculaWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: MatriculaStep = .aluno

    // Step fields
    @State private var nomeAluno = ""
    @State private var dataNascimento = Date()
    @State private var cpf = ""
    @State private var turmaSelecionada = "1º Ano A"
    @State private var nomeResponsavel = ""
    @State private var telefoneResponsavel = ""
    @State private var rgAnexado = false
    @State private var cpfAnexado = false
    @State private var comprovanteAnexado = false
    @State private var isSaving = false
    @State private var showSuccess = false

    private let turmas = ["1º Ano A", "1º Ano B", "2º Ano A", "2º Ano B", "3º Ano A"]

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                VStack(spacing: 0) {
                    stepperHeader
                    ScrollView {
                        VStack(spacing: 20) {
                            stepContent
                            navigationButtons
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var stepperHeader: some View {
        VStack(spacing: 16) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(SchoolPalette.secondaryText)
                        .padding(10)
                        .background(SchoolPalette.outline, in: Circle())
                }
                Spacer()
                Text("Nova Matrícula")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            HStack(spacing: 0) {
                ForEach(MatriculaStep.allCases, id: \.self) { step in
                    HStack(spacing: 0) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(step.rawValue <= currentStep.rawValue ? SchoolPalette.primary : SchoolPalette.outline)
                                    .frame(width: 32, height: 32)
                                if step.rawValue < currentStep.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                } else {
                                    Text("\(step.rawValue + 1)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundStyle(step.rawValue <= currentStep.rawValue ? .white : SchoolPalette.secondaryText)
                                }
                            }
                            Text(step.titulo)
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(step == currentStep ? SchoolPalette.primary : SchoolPalette.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        if step != MatriculaStep.allCases.last {
                            Rectangle()
                                .fill(step.rawValue < currentStep.rawValue ? SchoolPalette.primary : SchoolPalette.outline)
                                .frame(height: 2)
                                .padding(.bottom, 18)
                        }
                    }
                    if step != MatriculaStep.allCases.last { Spacer() }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(SchoolPalette.surface.opacity(0.9))
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .aluno:
            alunoStep
        case .turma:
            turmaStep
        case .responsavel:
            responsavelStep
        case .documentos:
            documentosStep
        case .confirmacao:
            confirmacaoStep
        }
    }

    private var alunoStep: some View {
        SchoolCard(title: "Dados do Aluno") {
            VStack(spacing: 14) {
                wizardField("Nome Completo", placeholder: "Nome do aluno", text: $nomeAluno)
                wizardField("CPF", placeholder: "000.000.000-00", text: $cpf)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Data de Nascimento")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                    DatePicker("", selection: $dataNascimento, displayedComponents: .date)
                        .labelsHidden()
                        .tint(SchoolPalette.primary)
                }
            }
        }
        .padding(.top, 16)
    }

    private var turmaStep: some View {
        SchoolCard(title: "Seleção de Turma") {
            VStack(spacing: 12) {
                ForEach(turmas, id: \.self) { turma in
                    Button {
                        turmaSelecionada = turma
                    } label: {
                        HStack {
                            Text(turma)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Spacer()
                            if turmaSelecionada == turma {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(SchoolPalette.primary)
                            } else {
                                Circle()
                                    .stroke(SchoolPalette.outline, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(14)
                        .background(turmaSelecionada == turma ? SchoolPalette.primary.opacity(0.06) : SchoolPalette.background, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(turmaSelecionada == turma ? SchoolPalette.primary.opacity(0.3) : SchoolPalette.outline))
                    }
                }
            }
        }
        .padding(.top, 16)
    }

    private var responsavelStep: some View {
        SchoolCard(title: "Responsável Legal") {
            VStack(spacing: 14) {
                wizardField("Nome do Responsável", placeholder: "Nome completo", text: $nomeResponsavel)
                wizardField("Telefone", placeholder: "(00) 00000-0000", text: $telefoneResponsavel)
            }
        }
        .padding(.top, 16)
    }

    private var documentosStep: some View {
        SchoolCard(title: "Documentos Necessários") {
            VStack(spacing: 12) {
                documentToggle("RG ou Certidão de Nascimento", isAttached: $rgAnexado)
                documentToggle("CPF do Responsável", isAttached: $cpfAnexado)
                documentToggle("Comprovante de Residência", isAttached: $comprovanteAnexado)
            }
        }
        .padding(.top, 16)
    }

    private var confirmacaoStep: some View {
        VStack(spacing: 16) {
            SchoolCard(title: "Resumo da Matrícula") {
                VStack(spacing: 12) {
                    confirmRow(label: "Aluno", value: nomeAluno.isEmpty ? "—" : nomeAluno)
                    confirmRow(label: "CPF", value: cpf.isEmpty ? "—" : cpf)
                    confirmRow(label: "Turma", value: turmaSelecionada)
                    confirmRow(label: "Responsável", value: nomeResponsavel.isEmpty ? "—" : nomeResponsavel)
                    confirmRow(label: "Documentos", value: [rgAnexado, cpfAnexado, comprovanteAnexado].filter { $0 }.count == 3 ? "Completos ✓" : "Incompletos")
                }
            }
            .padding(.top, 16)

            if showSuccess {
                SchoolCard {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(SchoolPalette.success)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Matrícula Enviada!")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text("Em análise pela secretaria.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                    }
                }
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentStep != .aluno {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        currentStep = MatriculaStep(rawValue: currentStep.rawValue - 1) ?? .aluno
                    }
                } label: {
                    Label("Voltar", systemImage: "chevron.left")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primary)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(SchoolPalette.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }
            }

            Button {
                if currentStep == .confirmacao {
                    submitMatricula()
                } else {
                    withAnimation(.spring(duration: 0.3)) {
                        currentStep = MatriculaStep(rawValue: currentStep.rawValue + 1) ?? .confirmacao
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if isSaving { ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.8) }
                    Text(currentStep == .confirmacao ? (isSaving ? "Enviando..." : "Confirmar Matrícula") : "Próximo")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(SchoolPalette.primary, in: RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isSaving)
        }
    }

    private func wizardField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
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

    private func documentToggle(_ label: String, isAttached: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: isAttached.wrappedValue ? "doc.fill" : "doc")
                .foregroundStyle(isAttached.wrappedValue ? SchoolPalette.success : SchoolPalette.secondaryText)
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
            Spacer()
            Toggle("", isOn: isAttached)
                .labelsHidden()
                .tint(SchoolPalette.primary)
        }
        .padding(14)
        .background(SchoolPalette.background, in: RoundedRectangle(cornerRadius: 12))
    }

    private func confirmRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
        }
    }

    private func submitMatricula() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaving = false
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
}

#Preview {
    MatriculaFlowView()
}
