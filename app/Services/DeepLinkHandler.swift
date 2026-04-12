// LS-50: Implementar Deep Links para notificações
import SwiftUI

// MARK: - Deep Link Route

enum DeepLinkRoute: Equatable {
    case student(id: String)
    case teacher(id: String)
    case attendance
    case calendar
    case dashboard
    case notification(id: String)

    // lexendscholar://student/stu-001
    // lexendscholar://teacher/t-1
    // lexendscholar://attendance
    // lexendscholar://calendar
    // lexendscholar://notification/notif-123
    static func from(url: URL) -> DeepLinkRoute? {
        guard url.scheme == "lexendscholar" else { return nil }
        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "student":
            let id = pathComponents.first ?? url.lastPathComponent
            return id.isEmpty ? nil : .student(id: id)
        case "teacher":
            let id = pathComponents.first ?? url.lastPathComponent
            return id.isEmpty ? nil : .teacher(id: id)
        case "attendance":
            return .attendance
        case "calendar":
            return .calendar
        case "dashboard":
            return .dashboard
        case "notification":
            let id = pathComponents.first ?? url.lastPathComponent
            return id.isEmpty ? nil : .notification(id: id)
        default:
            return nil
        }
    }

    var targetSection: SchoolSection {
        switch self {
        case .student: return .students
        case .teacher: return .teachers
        case .attendance: return .attendance
        case .calendar: return .calendar
        case .dashboard, .notification: return .dashboard
        }
    }
}

// MARK: - DeepLinkHandler

@MainActor
final class DeepLinkHandler: ObservableObject {
    static let shared = DeepLinkHandler()

    @Published private(set) var pendingRoute: DeepLinkRoute?
    @Published private(set) var targetStudentId: String?
    @Published private(set) var targetTeacherId: String?

    private init() {}

    func handle(url: URL) {
        guard let route = DeepLinkRoute.from(url: url) else {
            print("[DeepLinkHandler] Unrecognized URL: \(url)")
            return
        }
        apply(route: route)
    }

    func handle(userInfo: [AnyHashable: Any]) {
        // Parse push notification payload
        guard let type = userInfo["type"] as? String else { return }
        let entityId = userInfo["entity_id"] as? String ?? ""

        let route: DeepLinkRoute?
        switch type {
        case "student_alert":
            route = entityId.isEmpty ? nil : .student(id: entityId)
        case "teacher_update":
            route = entityId.isEmpty ? nil : .teacher(id: entityId)
        case "attendance_reminder":
            route = .attendance
        case "calendar_event":
            route = .calendar
        case "notification":
            route = entityId.isEmpty ? .dashboard : .notification(id: entityId)
        default:
            route = .dashboard
        }

        if let route {
            apply(route: route)
        }
    }

    func consumePendingRoute() -> DeepLinkRoute? {
        let route = pendingRoute
        pendingRoute = nil
        targetStudentId = nil
        targetTeacherId = nil
        return route
    }

    private func apply(route: DeepLinkRoute) {
        pendingRoute = route
        switch route {
        case .student(let id): targetStudentId = id
        case .teacher(let id): targetTeacherId = id
        default: break
        }
    }
}

// MARK: - Deep Link Navigation Modifier

struct DeepLinkNavigationModifier: ViewModifier {
    @ObservedObject private var handler = DeepLinkHandler.shared
    @Binding var selectedSection: SchoolSection

    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                handler.handle(url: url)
            }
            .onChange(of: handler.pendingRoute) { _, route in
                guard let route else { return }
                withAnimation {
                    selectedSection = route.targetSection
                }
            }
    }
}

extension View {
    func handlesDeepLinks(selection: Binding<SchoolSection>) -> some View {
        modifier(DeepLinkNavigationModifier(selectedSection: selection))
    }
}
