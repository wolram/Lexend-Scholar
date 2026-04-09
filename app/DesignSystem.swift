import SwiftUI

enum SchoolPalette {
    static let primary = Color(red: 19 / 255, green: 127 / 255, blue: 236 / 255)
    static let background = Color(red: 246 / 255, green: 247 / 255, blue: 248 / 255)
    static let surface = Color.white
    static let surfaceAlt = Color(red: 241 / 255, green: 243 / 255, blue: 253 / 255)
    static let primaryText = Color(red: 17 / 255, green: 20 / 255, blue: 24 / 255)
    static let secondaryText = Color(red: 97 / 255, green: 117 / 255, blue: 137 / 255)
    static let outline = Color.black.opacity(0.06)
    static let success = Color(red: 18 / 255, green: 150 / 255, blue: 91 / 255)
    static let warning = Color(red: 245 / 255, green: 158 / 255, blue: 11 / 255)
    static let danger = Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255)
    static let violet = Color(red: 99 / 255, green: 102 / 255, blue: 241 / 255)
}

struct SchoolCanvasBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    SchoolPalette.background,
                    Color.white,
                    SchoolPalette.surfaceAlt.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(SchoolPalette.primary.opacity(0.10))
                .frame(width: 360, height: 360)
                .offset(x: 240, y: -260)
                .blur(radius: 30)

            Circle()
                .fill(SchoolPalette.violet.opacity(0.08))
                .frame(width: 280, height: 280)
                .offset(x: -240, y: 360)
                .blur(radius: 24)
        }
        .ignoresSafeArea()
    }
}

struct AdaptiveGlassGroup<Content: View>: View {
    private let spacing: CGFloat
    private let content: () -> Content

    init(spacing: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

struct SchoolCard<Content: View>: View {
    private let title: String?
    private let subtitle: String?
    private let content: () -> Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            VStack(alignment: .leading, spacing: 18) {
                header
                content()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08))
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
        } else {
            VStack(alignment: .leading, spacing: 18) {
                header
                content()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SchoolPalette.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(SchoolPalette.outline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 18, y: 10)
        }
    }

    @ViewBuilder
    private var header: some View {
        if title != nil || subtitle != nil {
            VStack(alignment: .leading, spacing: 6) {
                if let title {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)
                }
            }
        }
    }
}

struct SchoolSectionHeader<Trailing: View>: View {
    private let eyebrow: String?
    private let title: String
    private let subtitle: String
    private let trailing: Trailing

    init(
        eyebrow: String? = nil,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .kerning(1.5)
                        .foregroundStyle(SchoolPalette.secondaryText)
                }

                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(SchoolPalette.primaryText)

                Text(subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(SchoolPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            trailing
        }
    }
}

struct StatusChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.12), in: Capsule())
    }
}

struct InitialAvatar: View {
    let name: String
    let accent: Color
    var size: CGFloat = 48

    private var initials: String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
    }

    var body: some View {
        Circle()
            .fill(accent.opacity(0.14))
            .frame(width: size, height: size)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }
    }
}

struct SchoolSearchBar: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(SchoolPalette.secondaryText)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .rounded))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(SchoolPalette.outline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 12, y: 8)
    }
}

struct MetricCard: View {
    let metric: DashboardMetric

    var body: some View {
        SchoolCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(metric.accent.opacity(0.12))
                        .frame(width: 52, height: 52)
                        .overlay {
                            Image(systemName: metric.symbol)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(metric.accent)
                        }

                    Spacer()

                    Text(metric.change)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(metric.changeColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(metric.changeColor.opacity(0.12), in: Capsule())
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(metric.title)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(SchoolPalette.secondaryText)

                    Text(metric.value)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(SchoolPalette.primaryText)
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func schoolProminentButton() -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
                .tint(SchoolPalette.primary)
        }
    }
}
