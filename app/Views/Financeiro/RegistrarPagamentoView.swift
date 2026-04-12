// LS-86: Implementar registro de pagamentos
import SwiftUI

struct RegistrarPagamentoView: View {
    let cobranca: Cobranca
    let onConfirmar: (Cobranca) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var dataPagamento = Date()
    @State private var valorPago: String = ""
    @State private var formaSelecionada: FormaPagamento = .pix
    @State private var isProcessing = false
    @State private var showConfirmacao = false
    @State private var cobrancaPaga: Cobranca? = nil

    private var valorNumerico: Double {
        let s = valorPago.replacingOccurrences(of: ",", with: ".")
        return Double(s) ?? 0
    }

    private var valorSugerido: Double {
        cobranca.status == .atrasado ? cobranca.valorComJuros : cobranca.valor
    }

    private var podePagar: Bool {
        valorNumerico > 0 && !isProcessing
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()

                if showConfirmacao, let paga = cobrancaPaga {
                    confirmacaoView(cobranca: paga)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    formularioView
                        .transition(.opacity)
                }
            }
            .navigationTitle("Registrar Pagamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !showConfirmacao {
                        Button("Cancelar") { dismiss() }
                            .tint(SchoolPalette.secondaryText)
                    }
                }
            }
            .onAppear {
                valorPago = String(format: "%.2f", valorSugerido)
            }
        }
    }

    // MARK: - Formulario

    private var formularioView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Info da cobrança
                SchoolCard(title: "Cobrança Selecionada") {
                    HStack(spacing: 14) {
                        InitialAvatar(name: cobranca.aluno, accent: cobranca.accent, size: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cobranca.aluno)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text(cobranca.descricao)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            HStack(spacing: 6) {
                                Text("Vencimento:")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)
                                Text(cobranca.vencimento, style: .date)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(cobranca.status == .atrasado ? SchoolPalette.danger : SchoolPalette.primaryText)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(valorSugerido, format: .currency(code: "BRL"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            StatusChip(text: cobranca.status.rawValue, color: cobranca.status.color)
                        }
                    }

                    if cobranca.status == .atrasado && cobranca.diasAtraso > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(SchoolPalette.danger)
                                .font(.system(size: 13))
                            Text("Juros de atraso: \(cobranca.diasAtraso) dias (+R$ \(String(format: "%.2f", cobranca.valorComJuros - cobranca.valor)))")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.danger)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(SchoolPalette.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Dados do pagamento
                SchoolCard(title: "Dados do Pagamento") {
                    VStack(spacing: 16) {
                        // Data
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Data do Pagamento", systemImage: "calendar")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            DatePicker("", selection: $dataPagamento, in: ...Date(), displayedComponents: [.date])
                                .labelsHidden()
                                .tint(SchoolPalette.primary)
                        }

                        Divider()

                        // Valor pago
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Valor Pago (R$)", systemImage: "dollarsign.circle")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            HStack {
                                Text("R$")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)
                                TextField("0,00", text: $valorPago)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.primaryText)
                                Spacer()
                                Button {
                                    valorPago = String(format: "%.2f", valorSugerido)
                                } label: {
                                    Text("Sugerido")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(SchoolPalette.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(SchoolPalette.primary.opacity(0.1), in: Capsule())
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(SchoolPalette.surfaceAlt, in: RoundedRectangle(cornerRadius: 12))
                        }

                        Divider()

                        // Forma de pagamento
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Forma de Pagamento", systemImage: "creditcard")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            HStack(spacing: 10) {
                                ForEach(FormaPagamento.allCases, id: \.self) { forma in
                                    formaButton(forma: forma)
                                }
                            }
                        }
                    }
                }

                // Botão confirmar
                Button {
                    confirmarPagamento()
                } label: {
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(isProcessing ? "Processando..." : "Confirmar Pagamento")
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        podePagar ? SchoolPalette.success : SchoolPalette.outline,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                }
                .disabled(!podePagar)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .padding(.bottom, 40)
        }
    }

    private func formaButton(forma: FormaPagamento) -> some View {
        let selecionada = formaSelecionada == forma
        return Button { formaSelecionada = forma } label: {
            VStack(spacing: 4) {
                Image(systemName: forma.icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(forma.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundStyle(selecionada ? .white : SchoolPalette.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selecionada ? SchoolPalette.primary : SchoolPalette.surfaceAlt, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selecionada ? SchoolPalette.primary : SchoolPalette.outline, lineWidth: 1.5)
            )
        }
    }

    // MARK: - Confirmacao

    private func confirmacaoView(cobranca: Cobranca) -> some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(SchoolPalette.success.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(SchoolPalette.success)
                }

                VStack(spacing: 8) {
                    Text("Pagamento Confirmado!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                    Text(cobranca.aluno)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                    Text(cobranca.valorPago ?? cobranca.valor, format: .currency(code: "BRL"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.success)
                }
            }

            VStack(spacing: 12) {
                Button {
                    onConfirmar(cobranca)
                } label: {
                    Label("Ver Recibo", systemImage: "doc.text")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SchoolPalette.primary, in: RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Fechar")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SchoolPalette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    // MARK: - Actions

    private func confirmarPagamento() {
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            var paga = cobranca
            paga.status = .pago
            paga.dataPagamento = dataPagamento
            paga.formaPagamento = formaSelecionada
            paga.valorPago = valorNumerico
            cobrancaPaga = paga
            isProcessing = false
            withAnimation(.spring(response: 0.4)) {
                showConfirmacao = true
            }
        }
    }
}

#Preview {
    RegistrarPagamentoView(cobranca: Cobranca.demo[1]) { _ in }
}
