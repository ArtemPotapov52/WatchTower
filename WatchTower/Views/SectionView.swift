import SwiftUI

struct SectionView: View {
    @Environment(\.colorScheme) var colorScheme
    let section: StatusSection

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader
            sectionContent
        }
    }

    private var sectionHeader: some View {
        HStack(spacing: 0) {
            Text(section.name.uppercased())
                .sectionHeaderStyle()
                .foregroundStyle(colors.textTertiary)
                .tracking(0.5)

            Spacer()

            switch section.state {
            case .loading:
                Text("загрузка")
                    .statusTextStyle()
                    .foregroundStyle(colors.textTertiary)
            case .ok:
                if section.items.isEmpty {
                    Text("нет данных")
                        .statusTextStyle()
                        .foregroundStyle(colors.textTertiary)
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppColors.success)
                            .frame(width: Spacing.statusDotSize, height: Spacing.statusDotSize)
                    }
                }
            case .warning:
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppColors.warning)
                        .frame(width: Spacing.statusDotSize, height: Spacing.statusDotSize)
                    Text("\(section.problemCount)/\(section.totalCount)")
                        .statusTextStyle()
                        .foregroundStyle(AppColors.warning)
                }
            case .error(let message):
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppColors.neutral)
                        .frame(width: Spacing.statusDotSize, height: Spacing.statusDotSize)
                    Text(message)
                        .statusTextStyle()
                        .foregroundStyle(colors.textTertiary)
                }
            }
        }
        .frame(height: Spacing.sectionHeaderHeight)
        .padding(.horizontal, Spacing.sectionPadding)
        .background(colors.surface)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section.state {
        case .loading:
            EmptyStateView(kind: .loading)
        case .ok, .warning:
            if section.items.isEmpty {
                EmptyStateView(kind: .notConfigured)
            } else {
                ForEach(section.items) { item in
                    RowView(item: item)
                }
            }
        case .error(let message):
            EmptyStateView(kind: .error(message))
        }
    }
}
