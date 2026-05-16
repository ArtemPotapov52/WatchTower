import SwiftUI

struct RowView: View {
    @Environment(\.colorScheme) var colorScheme
    let item: StatusItemModel

    @State private var isHovered = false

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        Button {
            if let urlString = item.actionURL, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 0) {
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.system(size: Spacing.iconSize))
                        .foregroundStyle(colors.textSecondary)
                        .frame(width: 16)
                        .padding(.trailing, Spacing.iconTitleGap)
                }

                HStack(spacing: 4) {
                    Text(item.title)
                        .bodyStyle()
                        .foregroundStyle(colors.textPrimary)
                        .lineLimit(1)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .statusTextStyle()
                            .foregroundStyle(colors.textTertiary)
                    }
                }

                Spacer(minLength: 8)

                statusDot
            }
            .frame(height: Spacing.rowHeight)
            .padding(.horizontal, Spacing.sectionPadding)
            .background(isHovered ? Color(white: 0.5).opacity(0.06) : .clear)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }

    @ViewBuilder
    private var statusDot: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(dotColor)
                .frame(width: Spacing.statusDotSize, height: Spacing.statusDotSize)

            Text(statusText)
                .statusTextStyle()
                .foregroundStyle(dotColor)
        }
    }

    private var dotColor: Color {
        switch item.status {
        case .success: return AppColors.success
        case .warning: return AppColors.warning
        case .danger: return AppColors.danger
        case .neutral: return AppColors.neutral
        }
    }

    private var statusText: String {
        switch item.status {
        case .success: return "ок"
        case .warning: return "внимание"
        case .danger: return "ошибка"
        case .neutral: return ""
        }
    }
}
