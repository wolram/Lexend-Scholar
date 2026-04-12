// LS-44: Implementar fluxo de login por perfil de usuário
import SwiftUI

struct ProfileSelectionView: View {
    @StateObject private var supabase = SupabaseService.shared
    @State private var isSigningOut = false

    var body: some View {
        ZStack {
            SchoolCanvasBackground()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    if let user = supabase.currentUser {
                        InitialAvatar(name: user.email ?? "U", accent: SchoolPalette.primary, size: 72)

                        VStack(spacing: 4) {
                            Text("Bem-vindo de volta")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                            Text(user.email ?? "")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                        }
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)

                // Profile role card
                if let user = supabase.currentUser {
                    VStack(spacing: 16) {
                        Text("SEU PERFIL")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .kerning(1.5)
                            .foregroundStyle(SchoolPalette.secondaryText)

                        ProfileRoleCard(role: user.role)
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()

                // Sign out
                Button {
                    Task {
                        isSigningOut = true
                        await supabase.signOut()
                        isSigningOut = false
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isSigningOut {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(SchoolPalette.secondaryText)
                                .scaleEffect(0.75)
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        Text(isSigningOut ? "Saindo..." : "Sair da conta")
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

private struct ProfileRoleCard: View {
    let role: UserRole

    var body: some View {
        SchoolCard {
            HStack(spacing: 20) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(role.accent.opacity(0.14))
                    .frame(width: 64, height: 64)
                    .overlay {
                        Image(systemName: role.symbol)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(role.accent)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    StatusChip(text: "Perfil Ativo", color: SchoolPalette.success)

                    Text(role.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)

                    Text(roleDescription(role))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private func roleDescription(_ role: UserRole) -> String {
        switch role {
        case .diretor: return "Acesso completo ao sistema — alunos, professores, relatórios e configurações."
        case .professor: return "Acesso à sala de aula, presença, notas e perfil de alunos."
        case .secretario: return "Acesso a cadastros, matrículas, turmas e relatórios administrativos."
        }
    }
}

// MARK: - App Root View (auth gate)

struct AppRootView: View {
    @StateObject private var supabase = SupabaseService.shared

    var body: some View {
        Group {
            if supabase.isAuthenticated {
                AppShellView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: supabase.isAuthenticated)
    }
}
