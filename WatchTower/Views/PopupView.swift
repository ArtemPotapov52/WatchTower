import SwiftUI

struct PopupView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppState.self) var state
    @Environment(\.openWindow) private var openWindow

    @State private var selectedFilter = "All"

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Separator()
            filterBar
            Separator()

            if state.hasProblems {
                statusBar
            }

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    let sections = state.filteredSections
                    if sections.isEmpty {
                        emptyFilter
                    } else {
                        ForEach(sections) { section in
                            SectionView(section: section)
                                .transition(.opacity)
                            if section.id != sections.last?.id {
                                Separator()
                            }
                        }
                    }
                }
            }

            Separator()
            footerView
        }
        .frame(width: Spacing.popupWidth)
        .background(colors.background)
        .onAppear {
            checkStaleData()
        }
        .task {
            await state.refreshLocalGit()
        }
        .onChange(of: state.popupFilterOptions) { _, options in
            if !options.contains(selectedFilter) {
                selectedFilter = "All"
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text("WatchTower")
                    .titleStyle()
                    .foregroundStyle(colors.textPrimary)
                if let user = state.gitUserName {
                    Text(user)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(colors.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                if !state.discoveredRepos.isEmpty {
                    Text("\(state.discoveredRepos.count) repo\(state.discoveredRepos.count.plural("","",""))")
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(colors.textTertiary)
                        .padding(.horizontal, 4)
                }

                if let lastUpdated = state.lastUpdated {
                    Text(TimeFormatter.relative(to: lastUpdated))
                        .statusTextStyle()
                        .foregroundStyle(colors.textTertiary)
                }

                Button {
                    Task { await state.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(colors.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(state.isRefreshing)
            }
        }
        .frame(height: Spacing.headerHeight)
        .padding(.horizontal, Spacing.sectionPadding)
        .background(colors.background)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(state.popupFilterOptions, id: \.self) { option in
                    Button {
                        selectedFilter = option
                        state.popupFilter = option == "All" ? nil : option
                    } label: {
                        Text(option)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(selectedFilter == option ? .white : colors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedFilter == option ? colors.textPrimary : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.sectionPadding)
            .padding(.vertical, 6)
        }
        .background(colors.background)
    }

    private var statusBar: some View {
        let problemCount = state.accounts.reduce(0) { acc, ac in
            guard ac.isEnabled else { return acc }
            let items = state.sectionItems[ac.id.uuidString] ?? []
            return acc + items.filter { $0.status == .danger || $0.status == .warning }.count
        }
        let needsToken = state.accounts.filter { !$0.isEnabled && $0.token.isEmpty && $0.textValues["localPath"] == nil }.count
        let hasProblems = problemCount > 0
        let hasTokenNeeds = needsToken > 0
        return HStack(spacing: 6) {
            if hasProblems {
                Circle()
                    .fill(AppColors.danger)
                    .frame(width: 5, height: 5)
                Text("\(problemCount) проблема\(problemCount.plural("","ы",""))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.danger)
            }
            if hasTokenNeeds {
                Circle()
                    .fill(AppColors.warning)
                    .frame(width: 5, height: 5)
                Text("\(needsToken) нужд\(needsToken.plural("ается","аются","аются")) в токене")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(AppColors.warning)
            }
            Spacer()
        }
        .frame(height: 20)
        .padding(.horizontal, Spacing.sectionPadding)
        .background((hasProblems ? AppColors.danger : AppColors.warning).opacity(0.08))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var emptyFilter: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 18))
                .foregroundStyle(colors.textTertiary)
            Text("Nothing here")
                .font(.system(size: 11))
                .foregroundStyle(colors.textTertiary)
        }
        .frame(height: 80)
    }

    private var footerView: some View {
        HStack(spacing: 0) {
            Button("Open WatchTower") {
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .statusTextStyle()
            .foregroundStyle(colors.textTertiary)

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .statusTextStyle()
            .foregroundStyle(colors.textTertiary)
        }
        .frame(height: Spacing.footerHeight)
        .padding(.horizontal, Spacing.sectionPadding)
        .background(colors.background)
    }

    private func checkStaleData() {
        guard let lastUpdated = state.lastUpdated else {
            Task { await state.refreshAll() }
            return
        }
        if Date().timeIntervalSince(lastUpdated) > 120 {
            Task { await state.refreshAll() }
        }
    }
}

struct Separator: View {
    @Environment(\.colorScheme) var colorScheme
    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        Rectangle()
            .fill(colors.border)
            .frame(height: 1)
    }
}

private extension Int {
    func plural(_ one: String, _ few: String, _ many: String) -> String {
        let n = self % 100
        if n >= 11 && n <= 19 { return many }
        switch n % 10 {
        case 1: return one
        case 2, 3, 4: return few
        default: return many
        }
    }
}
