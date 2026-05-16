import SwiftUI

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppState.self) var state

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCards
                sectionsList
            }
            .padding(24)
            .frame(maxWidth: .infinity)
        }
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
        ], spacing: 12) {
            summaryCard(
                title: "Services",
                value: "\(state.accounts.filter(\.isEnabled).count)",
                icon: "link",
                color: colors.textPrimary
            )
            summaryCard(
                title: "Issues",
                value: "\(totalIssues)",
                icon: "exclamationmark.triangle",
                color: AppColors.danger
            )
            summaryCard(
                title: "Last Check",
                value: state.lastUpdated.map { TimeFormatter.relative(to: $0) } ?? "\u{2014}",
                icon: "clock",
                color: colors.textSecondary
            )
        }
        .padding(.bottom, 4)
    }

    private var totalIssues: Int {
        state.accounts.reduce(0) { acc, ac in
            let items = state.sectionItems[ac.id.uuidString] ?? []
            return acc + items.filter { $0.status == .danger || $0.status == .warning }.count
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(colors.textTertiary)
            }
            Text(value)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(colors.surface)
        .cornerRadius(10)
    }

    private var sectionsList: some View {
        VStack(spacing: 8) {
            if state.accounts.isEmpty {
                emptyState
            } else {
                ForEach(state.allSections) { section in
                    DashboardSectionCard(section: section)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "link")
                .font(.system(size: 32))
                .foregroundStyle(colors.textTertiary)
            Text("No services connected")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(colors.textPrimary)
            Text("Add your GitHub, Vercel, Sentry and other accounts\nto start monitoring from one place")
                .font(.system(size: 12))
                .foregroundStyle(colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct DashboardSectionCard: View {
    @Environment(\.colorScheme) var colorScheme
    let section: StatusSection

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: section.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(sectionColor)
                Text(section.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(colors.textPrimary)
                Spacer()
                if section.problemCount > 0 {
                    Text("\(section.problemCount) issue\(section.problemCount > 1 ? "s" : "")")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.danger)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppColors.danger.opacity(0.1))
                        .cornerRadius(4)
                } else if !section.items.isEmpty {
                    Text("All OK")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppColors.success.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if !section.items.isEmpty {
                Separator()
                    .padding(.leading, 16)

                ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                    dashboardRow(item)
                    if item.id != section.items.last?.id {
                        Separator()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .background(colors.surface)
        .cornerRadius(10)
    }

    private var sectionColor: Color {
        switch section.state {
        case .loading: return AppColors.neutral
        case .ok: return AppColors.success
        case .warning: return AppColors.warning
        case .error: return AppColors.danger
        }
    }

    private func dashboardRow(_ item: StatusItemModel) -> some View {
        Button {
            if let urlString = item.actionURL, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 0) {
                if let icon = item.icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(colors.textSecondary)
                        .frame(width: 16)
                        .padding(.trailing, 8)
                }

                Text(item.title)
                    .font(.system(size: 12))
                    .foregroundStyle(colors.textPrimary)
                    .lineLimit(1)

                if let subtitle = item.subtitle {
                    Text("  \(subtitle)")
                        .font(.system(size: 11))
                        .foregroundStyle(colors.textTertiary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Circle()
                    .fill(item.status.color)
                    .frame(width: 6, height: 6)
            }
            .frame(height: 32)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}
