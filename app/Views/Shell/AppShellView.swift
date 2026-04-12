// LS-48: Criar shell do aplicativo com navegação lateral
import SwiftUI

struct AppShellView: View {
    @StateObject private var supabase = SupabaseService.shared
    @State private var selection: SchoolSection = .dashboard
    @State private var isPresentingAssignmentComposer = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            AppSidebar(
                selection: $selection,
                isPresentingAssignmentComposer: $isPresentingAssignmentComposer
            )
            .navigationSplitViewColumnWidth(min: 260, ideal: 290, max: 320)
        } detail: {
            Group {
                switch selection {
                case .dashboard:
                    ShellDashboardPlaceholder()
                case .students:
                    AlunosListView()
                case .teachers:
                    ProfessoresListView()
                case .classes:
                    ShellSectionPlaceholder(title: "Turmas", symbol: "book.closed.fill")
                case .attendance:
                    ShellSectionPlaceholder(title: "Presença", symbol: "checklist.checked")
                case .schedule:
                    ShellSectionPlaceholder(title: "Horários", symbol: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                case .calendar:
                    ShellSectionPlaceholder(title: "Calendário", symbol: "calendar")
                case .reports:
                    ShellSectionPlaceholder(title: "Relatórios", symbol: "chart.line.uptrend.xyaxis")
                case .settings:
                    ShellSectionPlaceholder(title: "Configurações", symbol: "gearshape.fill")
                }
            }
            .background(SchoolCanvasBackground())
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $isPresentingAssignmentComposer) {
            ShellComposerPlaceholder()
        }
    }
}

// MARK: - Sidebar

private struct AppSidebar: View {
    @StateObject private var supabase = SupabaseService.shared
    @Binding var selection: SchoolSection
    @Binding var isPresentingAssignmentComposer: Bool
    @State private var isSigningOut = false

    // Sections available per role
    private var allowedSections: [SchoolSection] {
        guard let user = supabase.currentUser else { return [] }
        switch user.role {
        case .diretor:
            return SchoolSection.allCases
        case .professor:
            return [.dashboard, .students, .classes, .attendance, .schedule, .calendar]
        case .secretario:
            return [.dashboard, .students, .teachers, .classes, .calendar, .reports, .settings]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Brand
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(SchoolPalette.primary)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Lexend Scholar")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                    if let user = supabase.currentUser {
                        Text(user.role.displayName.uppercased())
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .kerning(1.2)
                            .foregroundStyle(user.role.accent)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 16)

            // Nav list
            List {
                ForEach(allowedSections) { section in
                    Button {
                        selection = section
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: section.symbol)
                                .font(.system(size: 14, weight: .bold))
                                .frame(width: 20)
                            Text(section.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(selection == section ? SchoolPalette.primary : SchoolPalette.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selection == section ? SchoolPalette.primary.opacity(0.12) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)

            Divider()
                .padding(.horizontal, 16)

            // Bottom: user info + actions
            VStack(alignment: .leading, spacing: 16) {
                if let user = supabase.currentUser {
                    HStack(spacing: 12) {
                        InitialAvatar(name: user.email ?? "U", accent: user.role.accent, size: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.role.displayName)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(SchoolPalette.primaryText)
                            Text(user.email ?? "")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(SchoolPalette.secondaryText)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }

                Button {
                    isPresentingAssignmentComposer = true
                } label: {
                    Label("Nova Tarefa", systemImage: "square.and.pencil")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                }
                .schoolProminentButton()

                Button {
                    Task {
                        isSigningOut = true
                        await supabase.signOut()
                        isSigningOut = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isSigningOut {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(SchoolPalette.secondaryText)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                        Text(isSigningOut ? "Saindo..." : "Sair")
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [SchoolPalette.background, Color.white.opacity(0.94)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

// MARK: - Placeholder Views

private struct ShellDashboardPlaceholder: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SchoolSectionHeader(eyebrow: "Visão Geral", title: "Dashboard", subtitle: "Resumo do dia letivo") {
                    EmptyView()
                }
                Text("Conectado ao Supabase. Dados em tempo real disponíveis.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
            }
            .padding(32)
        }
    }
}

private struct ShellSectionPlaceholder: View {
    let title: String
    let symbol: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(SchoolPalette.primary.opacity(0.5))
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(SchoolPalette.primaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ShellComposerPlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Criar nova tarefa")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .navigationTitle("Nova Tarefa")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
