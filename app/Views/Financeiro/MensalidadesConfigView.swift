import SwiftUI

// MARK: - Models

struct PlanoMensalidade: Identifiable {
    let id: String
    var nome: String
    var valor: Double
    var vencimentoDia: Int
    var desconto: Double
    var turmas: [String]
    var descricao: String
    var ativo: Bool
    let accent: Color
}

struct ContratoConfig: Identifiable {
    let id: String
    var titulo: String
    var clausulas: [String]
    var vigenciaAnos: Int
    var reajusteAnual: Double
    var multaAtraso: Double
    var jurosDia: Double
}

// MARK: - MensalidadesConfigView

struct MensalidadesConfigView: View {
    @State private var planos: [PlanoMensalidade] = PlanoMensalidade.demo
    @State private var contrato: ContratoConfig = .demo
    @State private var selectedTab = 0
    @State private var showAddPlano = false
    @State private var editingPlano: PlanoMensalidade?
    @State private var isSaving = false
    @State private var showSaved = false

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection
                        tabSelector
                        if selectedTab == 0 {
                            planosSection
                        } else {
                            contratoSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddPlano) {
                PlanoFormView(plano: nil) { _ in }
            }
            .sheet(item: $editingPlano) { plano in
                PlanoFormView(plano: plano) { updated in
                    if let idx = planos.firstIndex(where: { $0.id == updated.id }) {
                        planos[idx] = updated
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        SchoolSectionHeader(
            eyebrow: "Financeiro",
            title: "Mensalidades",
            subtitle: "\(planos.filter { $0.ativo }.count) planos ativos"
        ) {
            Button { showAddPlano = true } label: {
                Label("Novo Plano", systemImage: "plus")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(SchoolPalette.primary, in: Capsule())
            }
        }
        .padding(.top, 24)
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["Planos", "Contratos"], id: \.self) { tab in
                let idx = tab == "Planos" ? 0 : 1
                Button {
                    withAnimation(.spring(duration: 0.3)) { selectedTab = idx }
                } label: {
                    Text(tab)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(selectedTab == idx ? .white : SchoolPalette.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == idx ? SchoolPalette.primary : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(4)
        .background(SchoolPalette.outline, in: RoundedRectangle(cornerRadius: 16))
    }

    private var planosSection: some View {
        VStack(spacing: 14) {
            ForEach(planos) { plano in
                PlanoCard(plano: plano) {
                    editingPlano = plano
                }
            }
        }
    }

    private var contratoSection: some View {
        VStack(spacing: 16) {
            SchoolCard(title: "Configuração de Contratos") {
                VStack(spacing: 16) {
                    contratoRow(label: "Vigência Padrão", value: "\(contrato.vigenciaAnos) ano(s)")
                    contratoRow(label: "Reajuste Anual", value: String(format: "%.1f%%", contrato.reajusteAnual))
                    contratoRow(label: "Multa por Atraso", value: String(format: "%.1f%%", contrato.multaAtraso))
                    contratoRow(label: "Juros ao Dia", value: String(format: "%.2f%%", contrato.jurosDia))
                }
            }

            SchoolCard(title: "Cláusulas Padrão") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(contrato.clausulas.indices, id: \.self) { idx in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(idx + 1).")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primary)
                                .frame(width: 20)
                            Text(contrato.clausulas[idx])
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Button {
                isSaving = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isSaving = false
                    showSaved = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showSaved = false }
                }
            } label: {
                HStack(spacing: 8) {
                    if isSaving { ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.8) }
                    Text(isSaving ? "Salvando..." : showSaved ? "Configurações Salvas!" : "Salvar Configurações")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(showSaved ? SchoolPalette.success : SchoolPalette.primary, in: RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isSaving)
            .animation(.spring(duration: 0.3), value: showSaved)
        }
    }

    private func contratoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
        }
    }
}

// MARK: - PlanoCard

struct PlanoCard: View {
    let plano: PlanoMensalidade
    let onEdit: () -> Void

    var body: some View {
        SchoolCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plano.nome)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(SchoolPalette.primaryText)
                        Text(plano.descricao)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(SchoolPalette.secondaryText)
                    }
                    Spacer()
                    StatusChip(text: plano.ativo ? "Ativo" : "Inativo", color: plano.ativo ? SchoolPalette.success : SchoolPalette.secondaryText)
                }

                HStack(spacing: 16) {
                    valueItem(label: "Valor Mensal", value: "R$ \(String(format: "%.2f", plano.valor))")
                    Divider().frame(height: 32)
                    valueItem(label: "Vencimento", value: "Dia \(plano.vencimentoDia)")
                    Divider().frame(height: 32)
                    valueItem(label: "Desconto", value: "\(String(format: "%.0f", plano.desconto))%")
                }

                if !plano.turmas.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(plano.turmas, id: \.self) { turma in
                                Text(turma)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundStyle(plano.accent)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(plano.accent.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }

                Button(action: onEdit) {
                    Label("Editar Plano", systemImage: "pencil")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(SchoolPalette.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func valueItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
        }
    }
}

// MARK: - PlanoFormView

struct PlanoFormView: View {
    let plano: PlanoMensalidade?
    let onSave: (PlanoMensalidade) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var nome: String
    @State private var valorStr: String
    @State private var vencimentoDia: Int
    @State private var desconto: String
    @State private var descricao: String
    @State private var ativo: Bool
    @State private var isSaving = false

    init(plano: PlanoMensalidade?, onSave: @escaping (PlanoMensalidade) -> Void) {
        self.plano = plano
        self.onSave = onSave
        _nome = State(initialValue: plano?.nome ?? "")
        _valorStr = State(initialValue: plano.map { String(format: "%.2f", $0.valor) } ?? "")
        _vencimentoDia = State(initialValue: plano?.vencimentoDia ?? 10)
        _desconto = State(initialValue: plano.map { String(format: "%.0f", $0.desconto) } ?? "0")
        _descricao = State(initialValue: plano?.descricao ?? "")
        _ativo = State(initialValue: plano?.ativo ?? true)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        SchoolCard(title: plano == nil ? "Novo Plano" : "Editar Plano") {
                            VStack(spacing: 14) {
                                formField("Nome do Plano", placeholder: "Ex: Plano Básico", text: $nome)
                                formField("Valor Mensal (R$)", placeholder: "0,00", text: $valorStr)
                                    .keyboardType(.decimalPad)
                                formField("Desconto (%)", placeholder: "0", text: $desconto)
                                    .keyboardType(.numberPad)
                                formField("Descrição", placeholder: "Descrição do plano", text: $descricao)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Dia de Vencimento")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(SchoolPalette.secondaryText)
                                    Picker("Vencimento", selection: $vencimentoDia) {
                                        ForEach([5, 10, 15, 20, 25], id: \.self) { dia in
                                            Text("Dia \(dia)").tag(dia)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                Toggle("Plano Ativo", isOn: $ativo)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .tint(SchoolPalette.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        Button {
                            salvar()
                        } label: {
                            HStack(spacing: 8) {
                                if isSaving { ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.8) }
                                Text(isSaving ? "Salvando..." : "Salvar Plano")
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(nome.isEmpty ? SchoolPalette.outline : SchoolPalette.primary, in: RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                        }
                        .disabled(nome.isEmpty || isSaving)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(plano == nil ? "Novo Plano" : "Editar Plano")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.tint(SchoolPalette.secondaryText)
                }
            }
        }
    }

    private func formField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
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

    private func salvar() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            let updated = PlanoMensalidade(
                id: plano?.id ?? UUID().uuidString,
                nome: nome,
                valor: Double(valorStr.replacingOccurrences(of: ",", with: ".")) ?? 0,
                vencimentoDia: vencimentoDia,
                desconto: Double(desconto) ?? 0,
                turmas: plano?.turmas ?? [],
                descricao: descricao,
                ativo: ativo,
                accent: plano?.accent ?? SchoolPalette.primary
            )
            onSave(updated)
            dismiss()
        }
    }
}

// MARK: - Demo Data

extension PlanoMensalidade {
    static let demo: [PlanoMensalidade] = [
        PlanoMensalidade(id: "pm-1", nome: "Plano Básico", valor: 850.00, vencimentoDia: 10, desconto: 0, turmas: ["1º Ano A", "1º Ano B"], descricao: "Plano para alunos do 1º ano com material incluso.", ativo: true, accent: SchoolPalette.primary),
        PlanoMensalidade(id: "pm-2", nome: "Plano Integral", valor: 1_200.00, vencimentoDia: 5, desconto: 5, turmas: ["2º Ano A", "3º Ano A"], descricao: "Plano integral com aulas de reforço e atividades extras.", ativo: true, accent: SchoolPalette.violet),
        PlanoMensalidade(id: "pm-3", nome: "Plano Bolsista", valor: 425.00, vencimentoDia: 15, desconto: 50, turmas: ["Todas"], descricao: "Plano com 50% de desconto para alunos bolsistas.", ativo: true, accent: SchoolPalette.success),
        PlanoMensalidade(id: "pm-4", nome: "Plano 2025 (Encerrado)", valor: 800.00, vencimentoDia: 10, desconto: 0, turmas: [], descricao: "Plano do ano letivo 2025.", ativo: false, accent: SchoolPalette.secondaryText)
    ]
}

extension ContratoConfig {
    static let demo = ContratoConfig(
        id: "cc-1",
        titulo: "Contrato de Prestação de Serviços Educacionais",
        clausulas: [
            "O responsável compromete-se a efetuar o pagamento das mensalidades até a data de vencimento estipulada.",
            "Em caso de inadimplência superior a 30 dias, o aluno poderá ser impedido de assistir às aulas.",
            "O reajuste anual será aplicado conforme o índice IPCA do período.",
            "A rescisão do contrato deve ser comunicada com antecedência mínima de 30 dias."
        ],
        vigenciaAnos: 1,
        reajusteAnual: 6.5,
        multaAtraso: 2.0,
        jurosDia: 0.033
    )
}

#Preview {
    MensalidadesConfigView()
}
