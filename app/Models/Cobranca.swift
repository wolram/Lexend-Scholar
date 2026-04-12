// LS-85: Implementar geração de cobranças mensais
import Foundation
import SwiftUI

// MARK: - StatusCobranca

enum StatusCobranca: String, CaseIterable, Codable {
    case pendente = "Pendente"
    case pago = "Pago"
    case atrasado = "Atrasado"
    case cancelado = "Cancelado"

    var color: Color {
        switch self {
        case .pendente:  return SchoolPalette.warning
        case .pago:      return SchoolPalette.success
        case .atrasado:  return SchoolPalette.danger
        case .cancelado: return SchoolPalette.secondaryText
        }
    }

    var icon: String {
        switch self {
        case .pendente:  return "clock.fill"
        case .pago:      return "checkmark.circle.fill"
        case .atrasado:  return "exclamationmark.triangle.fill"
        case .cancelado: return "xmark.circle.fill"
        }
    }
}

// MARK: - FormaPagamento

enum FormaPagamento: String, CaseIterable, Codable {
    case pix     = "PIX"
    case boleto  = "Boleto"
    case cartao  = "Cartão"
    case dinheiro = "Dinheiro"

    var icon: String {
        switch self {
        case .pix:      return "qrcode"
        case .boleto:   return "barcode"
        case .cartao:   return "creditcard.fill"
        case .dinheiro: return "banknote.fill"
        }
    }
}

// MARK: - Cobranca

struct Cobranca: Identifiable, Codable {
    let id: String
    let alunoId: String
    let aluno: String
    let turma: String
    let descricao: String
    let mes: Int
    let ano: Int
    let valor: Double
    let vencimento: Date
    var status: StatusCobranca
    var dataPagamento: Date?
    var formaPagamento: FormaPagamento?
    var valorPago: Double?

    // Computed — não Codable, mas derivados
    var diasAtraso: Int {
        guard status == .atrasado else { return 0 }
        let diff = Calendar.current.dateComponents([.day], from: vencimento, to: Date()).day ?? 0
        return max(0, diff)
    }

    var valorComJuros: Double {
        guard status == .atrasado, diasAtraso > 0 else { return valor }
        // Juros de 0.033% ao dia (aprox. 1% ao mês)
        return valor * (1 + 0.00033 * Double(diasAtraso))
    }

    var competencia: String {
        let names = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
                     "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
        guard mes >= 1 && mes <= 12 else { return "\(mes)/\(ano)" }
        return "\(names[mes - 1])/\(ano)"
    }

    var accent: Color {
        switch status {
        case .pago:      return SchoolPalette.success
        case .atrasado:  return SchoolPalette.danger
        case .pendente:  return SchoolPalette.warning
        case .cancelado: return SchoolPalette.secondaryText
        }
    }
}

// MARK: - Demo Data

extension Cobranca {
    static let demo: [Cobranca] = {
        let cal = Calendar.current
        let base = Date()
        func d(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: base) ?? base }
        return [
            Cobranca(id: "cb-1", alunoId: "a-1", aluno: "Sophia Anderson",  turma: "1º Ano A", descricao: "Mensalidade Abril/2026",    mes: 4, ano: 2026, valor: 850.00,   vencimento: d(-5),  status: .pago,     dataPagamento: d(-4), formaPagamento: .pix,      valorPago: 850.00),
            Cobranca(id: "cb-2", alunoId: "a-2", aluno: "Elena Rodriguez",  turma: "2º Ano B", descricao: "Mensalidade Abril/2026",    mes: 4, ano: 2026, valor: 1_200.00, vencimento: d(5),   status: .pendente, dataPagamento: nil,   formaPagamento: nil,       valorPago: nil),
            Cobranca(id: "cb-3", alunoId: "a-3", aluno: "Jordan Lee",       turma: "3º Ano C", descricao: "Mensalidade Março/2026",    mes: 3, ano: 2026, valor: 850.00,   vencimento: d(-20), status: .atrasado, dataPagamento: nil,   formaPagamento: nil,       valorPago: nil),
            Cobranca(id: "cb-4", alunoId: "a-4", aluno: "Gabriel Souza",    turma: "1º Ano A", descricao: "Mensalidade Abril/2026",    mes: 4, ano: 2026, valor: 425.00,   vencimento: d(10),  status: .pendente, dataPagamento: nil,   formaPagamento: nil,       valorPago: nil),
            Cobranca(id: "cb-5", alunoId: "a-5", aluno: "Isabella Martins", turma: "2º Ano B", descricao: "Mensalidade Fevereiro/2026",mes: 2, ano: 2026, valor: 1_200.00, vencimento: d(-40), status: .atrasado, dataPagamento: nil,   formaPagamento: nil,       valorPago: nil),
            Cobranca(id: "cb-6", alunoId: "a-6", aluno: "Lucas Ferreira",   turma: "3º Ano C", descricao: "Mensalidade Abril/2026",    mes: 4, ano: 2026, valor: 850.00,   vencimento: d(5),   status: .pago,     dataPagamento: d(-1), formaPagamento: .cartao,   valorPago: 850.00),
            Cobranca(id: "cb-7", alunoId: "a-7", aluno: "Ana Lima",         turma: "1º Ano B", descricao: "Mensalidade Abril/2026",    mes: 4, ano: 2026, valor: 650.00,   vencimento: d(6),   status: .pendente, dataPagamento: nil,   formaPagamento: nil,       valorPago: nil),
            Cobranca(id: "cb-8", alunoId: "a-8", aluno: "Pedro Costa",      turma: "2º Ano A", descricao: "Mensalidade Março/2026",    mes: 3, ano: 2026, valor: 950.00,   vencimento: d(-15), status: .atrasado, dataPagamento: nil,   formaPagamento: nil,       valorPago: nil),
            Cobranca(id: "cb-9", alunoId: "a-2", aluno: "Elena Rodriguez",  turma: "2º Ano B", descricao: "Mensalidade Março/2026",    mes: 3, ano: 2026, valor: 1_200.00, vencimento: d(-25), status: .pago,     dataPagamento: d(-24),formaPagamento: .boleto,   valorPago: 1_200.00),
        ]
    }()
}
