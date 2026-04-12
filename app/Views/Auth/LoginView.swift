// LS-44: Implementar fluxo de login por perfil de usuário
import SwiftUI

struct LoginView: View {
    @StateObject private var supabase = SupabaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @FocusState private var focusedField: LoginField?

    enum LoginField { case email, password }

    var body: some View {
        ZStack {
            SchoolCanvasBackground()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)

                    // Logo
                    VStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(SchoolPalette.primary)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .shadow(color: SchoolPalette.primary.opacity(0.35), radius: 20, y: 10)

                        VStack(spacing: 6) {
                            Text("Lexend Scholar")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text("SISTEMA DE GESTÃO ESCOLAR")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .kerning(1.5)
                                .foregroundStyle(SchoolPalette.secondaryText)
                        }
                    }
                    .padding(.bottom, 48)

                    // Form card
                    SchoolCard(title: "Entrar na conta") {
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("E-mail institucional", systemImage: "envelope")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)

                                TextField("usuario@escola.edu.br", text: $email)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focusedField, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .password }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(SchoolPalette.background)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                focusedField == .email ? SchoolPalette.primary : SchoolPalette.outline,
                                                lineWidth: focusedField == .email ? 2 : 1
                                            )
                                    )
                                    .animation(.easeInOut(duration: 0.15), value: focusedField)
                            }

                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Senha", systemImage: "lock")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(SchoolPalette.secondaryText)

                                SecureField("••••••••", text: $password)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit { Task { await attemptLogin() } }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(SchoolPalette.background)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                focusedField == .password ? SchoolPalette.primary : SchoolPalette.outline,
                                                lineWidth: focusedField == .password ? 2 : 1
                                            )
                                    )
                                    .animation(.easeInOut(duration: 0.15), value: focusedField)
                            }

                            // Error
                            if let error = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(SchoolPalette.danger)
                                        .font(.system(size: 14))
                                    Text(error)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(SchoolPalette.danger)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(SchoolPalette.danger.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            // Login button
                            Button {
                                Task { await attemptLogin() }
                            } label: {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                            .scaleEffect(0.85)
                                    } else {
                                        Image(systemName: "arrow.right.circle.fill")
                                    }
                                    Text(isLoading ? "Entrando..." : "Entrar")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(canLogin ? SchoolPalette.primary : SchoolPalette.secondaryText)
                                )
                                .animation(.easeInOut(duration: 0.2), value: canLogin)
                            }
                            .disabled(!canLogin || isLoading)
                        }
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: 480)

                    Spacer(minLength: 60)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var canLogin: Bool {
        email.contains("@") && password.count >= 6
    }

    private func attemptLogin() async {
        guard canLogin else { return }
        focusedField = nil
        isLoading = true
        errorMessage = nil
        do {
            try await supabase.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
