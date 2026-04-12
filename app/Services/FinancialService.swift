// LS-206: FinancialService conectado ao Supabase com fallback DemoData
import Foundation
import Observation

@Observable
final class FinancialService {
    var cobrancas: [Cobranca] = []
    var isLoading = false
    var errorMessage: String?

    private let supabase = SupabaseService.shared

    // MARK: - Fetch

    func fetchCobrancas() async {
        isLoading = true
        errorMessage = nil
        do {
            let dtos: [CobrancaDTO] = try await supabase.fetch(from: "financial_records")
            cobrancas = dtos.map { $0.toCobranca() }
        } catch {
            #if DEBUG
            cobrancas = Cobranca.demo
            #else
            errorMessage = "Erro ao carregar cobranças: \(error.localizedDescription)"
            #endif
        }
        isLoading = false
    }

    func registrarPagamento(cobrancaId: String, valor: Double, forma: FormaPagamento, data: Date) async throws {
        struct PagamentoUpdate: Encodable {
            let id: String
            let valorPago: Double
            let formaPagamento: String
            let dataPagamento: String
            let status: String
        }
        let update = PagamentoUpdate(
            id: cobrancaId,
            valorPago: valor,
            formaPagamento: forma.rawValue,
            dataPagamento: ISO8601DateFormatter().string(from: data),
            status: "pago"
        )
        _ = try await supabase.update(table: "financial_records", id: cobrancaId, value: update)
        await fetchCobrancas()
    }

    func gerarCobrancasDoMes(mes: Int, ano: Int) async throws {
        struct GeracaoPayload: Encodable {
            let mes: Int
            let ano: Int
        }
        _ = try await supabase.insert(into: "financial_records", value: GeracaoPayload(mes: mes, ano: ano))
        await fetchCobrancas()
    }

    // MARK: - Computed

    var cobrancasPendentes: [Cobranca] { cobrancas.filter { $0.status == .pendente } }
    var cobrancasAtrasadas: [Cobranca] { cobrancas.filter { $0.status == .atrasado } }
    var cobrancasPagas: [Cobranca] { cobrancas.filter { $0.status == .pago } }
    var totalArrecadado: Double { cobrancasPagas.reduce(0) { $0 + ($1.valorPago ?? $1.valor) } }
    var totalPendente: Double { cobrancasPendentes.reduce(0) { $0 + $1.valor } }
    var totalAtrasado: Double { cobrancasAtrasadas.reduce(0) { $0 + $1.valorComJuros } }
}

// MARK: - DTO

struct CobrancaDTO: Codable {
    let id: String
    let studentId: String?
    let studentName: String?
    let turma: String?
    let descricao: String?
    let mes: Int?
    let ano: Int?
    let valor: Double?
    let status: String?
    let dueDate: String?
    let paymentDate: String?
    let paymentMethod: String?
    let valorPago: Double?

    enum CodingKeys: String, CodingKey {
        case id, mes, ano, valor, status, turma, descricao
        case studentId = "student_id"
        case studentName = "student_name"
        case dueDate = "due_date"
        case paymentDate = "payment_date"
        case paymentMethod = "payment_method"
        case valorPago = "valor_pago"
    }

    func toCobranca() -> Cobranca {
        let statusEnum: StatusCobranca = {
            switch status {
            case "pago", "Pago": return .pago
            case "atrasado", "Atrasado": return .atrasado
            case "cancelado", "Cancelado": return .cancelado
            default: return .pendente
            }
        }()
        let vencimento = dueDate.flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        let pagamentoDate = paymentDate.flatMap { ISO8601DateFormatter().date(from: $0) }
        let formaEnum = paymentMethod.flatMap { FormaPagamento(rawValue: $0) }
        return Cobranca(
            id: id,
            alunoId: studentId ?? "",
            aluno: studentName ?? "",
            turma: turma ?? "",
            descricao: descricao ?? "Mensalidade",
            mes: mes ?? 1,
            ano: ano ?? 2025,
            valor: valor ?? 0,
            vencimento: vencimento,
            status: statusEnum,
            dataPagamento: pagamentoDate,
            formaPagamento: formaEnum,
            valorPago: valorPago
        )
    }
}
