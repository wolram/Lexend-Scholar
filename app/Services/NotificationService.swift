import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Type

enum NotificationType: String {
    case novaMensagem = "nova_mensagem"
    case comunicado = "comunicado"
    case cobrancaVencendo = "cobranca_vencendo"
    case frequenciaBaixa = "frequencia_baixa"
}

// MARK: - NotificationService

@MainActor
final class NotificationService: NSObject, ObservableObject {

    static let shared = NotificationService()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var deviceToken: String?

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Request Authorization

    /// Solicita permissão para enviar notificações ao usuário.
    /// Deve ser chamado durante o onboarding, após o usuário entender o valor das notificações.
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await refreshAuthorizationStatus()
            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("[NotificationService] Erro ao solicitar autorização: \(error)")
        }
    }

    // MARK: - Register for Remote Notifications

    /// Registra o dispositivo para receber notificações remotas via APNs.
    /// Deve ser chamado após o usuário conceder permissão.
    func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }

    // MARK: - Device Token

    /// Armazena o device token APNs recebido no AppDelegate.
    /// - Parameter tokenData: Data recebida em `didRegisterForRemoteNotificationsWithDeviceToken`
    func didRegisterDeviceToken(_ tokenData: Data) {
        let token = tokenData
            .map { String(format: "%02.2hhx", $0) }
            .joined()
        deviceToken = token
        print("[NotificationService] Device token registrado: \(token)")
        // TODO: Enviar token ao backend (Supabase) vinculado ao usuário autenticado
    }

    func didFailToRegisterDeviceToken(error: Error) {
        print("[NotificationService] Falha ao registrar para notificações remotas: \(error)")
    }

    // MARK: - Handle Notification

    /// Roteia uma notificação recebida para a tela correta com base no tipo.
    /// - Parameter notification: Notificação recebida pelo sistema
    func handleNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        guard
            let typeRaw = userInfo["type"] as? String,
            let type = NotificationType(rawValue: typeRaw)
        else {
            print("[NotificationService] Notificação sem tipo definido: \(userInfo)")
            return
        }

        switch type {
        case .novaMensagem:
            handleNovaMensagem(userInfo: userInfo)
        case .comunicado:
            handleComunicado(userInfo: userInfo)
        case .cobrancaVencendo:
            handleCobrancaVencendo(userInfo: userInfo)
        case .frequenciaBaixa:
            handleFrequenciaBaixa(userInfo: userInfo)
        }
    }

    // MARK: - Authorization Status

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Private Handlers

    private func handleNovaMensagem(userInfo: [AnyHashable: Any]) {
        let mensagemId = userInfo["mensagem_id"] as? String
        print("[NotificationService] Nova mensagem recebida. ID: \(mensagemId ?? "desconhecido")")
        // TODO: Navegar para a tela de mensagens / DeepLink para mensagemId
        NotificationCenter.default.post(
            name: .notificationNovaMensagem,
            object: nil,
            userInfo: userInfo
        )
    }

    private func handleComunicado(userInfo: [AnyHashable: Any]) {
        let comunicadoId = userInfo["comunicado_id"] as? String
        print("[NotificationService] Comunicado recebido. ID: \(comunicadoId ?? "desconhecido")")
        // TODO: Navegar para tela de comunicados
        NotificationCenter.default.post(
            name: .notificationComunicado,
            object: nil,
            userInfo: userInfo
        )
    }

    private func handleCobrancaVencendo(userInfo: [AnyHashable: Any]) {
        let cobrancaId = userInfo["cobranca_id"] as? String
        print("[NotificationService] Cobrança vencendo. ID: \(cobrancaId ?? "desconhecido")")
        // TODO: Navegar para tela financeira
        NotificationCenter.default.post(
            name: .notificationCobrancaVencendo,
            object: nil,
            userInfo: userInfo
        )
    }

    private func handleFrequenciaBaixa(userInfo: [AnyHashable: Any]) {
        let alunoId = userInfo["aluno_id"] as? String
        print("[NotificationService] Frequência baixa. Aluno ID: \(alunoId ?? "desconhecido")")
        // TODO: Navegar para tela de frequência do aluno
        NotificationCenter.default.post(
            name: .notificationFrequenciaBaixa,
            object: nil,
            userInfo: userInfo
        )
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {

    /// Exibe notificação mesmo com o app em foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Trata o tap do usuário na notificação
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotification(response.notification)
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let notificationNovaMensagem = Notification.Name("lexend.notification.novaMensagem")
    static let notificationComunicado = Notification.Name("lexend.notification.comunicado")
    static let notificationCobrancaVencendo = Notification.Name("lexend.notification.cobrancaVencendo")
    static let notificationFrequenciaBaixa = Notification.Name("lexend.notification.frequenciaBaixa")
}
