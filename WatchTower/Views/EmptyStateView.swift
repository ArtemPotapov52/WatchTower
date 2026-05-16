import SwiftUI

struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme
    let kind: EmptyKind

    @State private var pulseOpacity: Double = 0.3

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            switch kind {
            case .loading:
                Text("Загрузка...")
                    .statusTextStyle()
                    .foregroundStyle(colors.textTertiary)
                    .opacity(pulseOpacity)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                        ) {
                            pulseOpacity = 0.7
                        }
                    }
            case .notConfigured:
                Text("Добавить токен →")
                    .statusTextStyle()
                    .foregroundStyle(colors.textTertiary)
            case .error(let message):
                HStack(spacing: 6) {
                    Text(message)
                        .statusTextStyle()
                        .foregroundStyle(AppColors.neutral)
                    if message == "Нужен токен" {
                        Image(systemName: "gearshape")
                            .font(.system(size: 10))
                            .foregroundStyle(colors.textTertiary)
                    } else {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10))
                            .foregroundStyle(colors.textTertiary)
                    }
                }
            }
            Spacer()
        }
        .frame(height: Spacing.rowHeight)
        .padding(.horizontal, Spacing.sectionPadding)
    }

    enum EmptyKind {
        case loading
        case notConfigured
        case error(String)
    }
}
