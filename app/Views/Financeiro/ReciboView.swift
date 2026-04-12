// LS-88: Implementar emissão de recibos
import SwiftUI

struct ReciboView: View {
    let cobranca: Cobranca
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    private var textoRecibo: String {
        let dataStr = cobranca.dataPagamento.map { $0.formatted(date: .long, time: .omitted) } ?? "—"
        let formaStr = cobranca.formaPagamento?.rawValue ?? "—"
        let valorStr = String(format: "R$ %.2f", cobranca.valorPago ?? cobranca.valor)
        return """
        ============================
           RECIBO DE PAGAMENTO
        ============================
        ESCOLA: Lexend Scholar
        CNPJ: 00.000.000/0001-00
        ----------------------------
        ALUNO: \(cobranca.aluno)
        TURMA: \(cobranca.turma)
        COMPETÊNCIA: \(cobranca.competencia)
        ----------------------------
        DESCRIÇÃO: \(cobranca.descricao)
        VALOR PAGO: \(valorStr)
        DATA PAGAMENTO: \(dataStr)
        FORMA: \(formaStr)
        ----------------------------
        RECIBO Nº: \(cobranca.id.uppercased())
        ============================
        Lexend Scholar confirma o
        recebimento do valor acima.
        ============================
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SchoolCanvasBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        reciboCard
                        botoesAcao
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Recibo de Pagamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fechar") { dismiss() }
                        .tint(SchoolPalette.secondaryText)
                }
            }
        }
    }

    // MARK: - Recibo Card

    private var reciboCard: some View {
        SchoolCard {
            VStack(spacing: 0) {
                // Cabeçalho Escola
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(SchoolPalette.primary.opacity(0.1))
                            .frame(width: 64, height: 64)
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(SchoolPalette.primary)
                    }
                    Text("Lexend Scholar")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                    Text("RECIBO DE PAGAMENTO")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .kerning(2)
                        .foregroundStyle(SchoolPalette.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)

                Rectangle()
                    .fill(SchoolPalette.outline)
                    .frame(height: 1)
                    .padding(.bottom, 20)

                // Badge de pago
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(SchoolPalette.success)
                        Text("PAGO")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(SchoolPalette.success)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(SchoolPalette.success.opacity(0.1), in: Capsule())
                    .overlay(Capsule().stroke(SchoolPalette.success.opacity(0.3), lineWidth: 1.5))
                    Spacer()
                }
                .padding(.bottom, 20)

                // Dados Aluno
                reciboRow(label: "Aluno", value: cobranca.aluno)
                reciboRow(label: "Turma", value: cobranca.turma)
                reciboRow(label: "Competência", value: cobranca.competencia)
                reciboRow(label: "Descrição", value: cobranca.descricao)

                Rectangle()
                    .fill(SchoolPalette.outline)
                    .frame(height: 1)
                    .padding(.vertical, 16)

                // Dados Pagamento
                if let dataPag = cobranca.dataPagamento {
                    reciboRow(label: "Data Pagamento", value: dataPag.formatted(date: .long, time: .omitted))
                }
                if let forma = cobranca.formaPagamento {
                    reciboRow(label: "Forma", value: forma.rawValue)
                }

                Rectangle()
                    .fill(SchoolPalette.outline)
                    .frame(height: 1)
                    .padding(.vertical, 16)

                // Valor em destaque
                HStack {
                    Text("VALOR TOTAL PAGO")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                    Spacer()
                    Text(cobranca.valorPago ?? cobranca.valor, format: .currency(code: "BRL"))
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(SchoolPalette.success)
                }
                .padding(.bottom, 20)

                // Rodapé
                Rectangle()
                    .fill(SchoolPalette.outline)
                    .frame(height: 1)
                    .padding(.bottom, 16)

                VStack(spacing: 4) {
                    Text("Recibo nº \(cobranca.id.uppercased())")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(SchoolPalette.secondaryText)
                    Text("Lexend Scholar confirma o recebimento do valor acima.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func reciboRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(SchoolPalette.secondaryText)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.bottom, 10)
    }

    // MARK: - Botoes

    private var botoesAcao: some View {
        VStack(spacing: 12) {
            ShareLink(
                item: textoRecibo,
                preview: SharePreview(
                    "Recibo — \(cobranca.aluno)",
                    image: Image(systemName: "doc.text.fill")
                )
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Compartilhar Recibo")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(SchoolPalette.primary, in: RoundedRectangle(cornerRadius: 16))
            }

            Button { dismiss() } label: {
                Text("Fechar")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(SchoolPalette.surfaceAlt, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

#Preview {
    ReciboView(cobranca: {
        var c = Cobranca.demo[0]
        c.status = .pago
        c.dataPagamento = Date()
        c.formaPagamento = .pix
        c.valorPago = 850.00
        return c
    }())
}
