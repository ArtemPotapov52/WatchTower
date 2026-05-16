import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: TabType = .dashboard

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Separator()
                .frame(width: 1)
            content
        }
        .frame(minWidth: 720, minHeight: 480)
        .background(colors.background)
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 2) {
                ForEach(TabType.allCases, id: \.self) { tab in
                    sidebarTab(tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Spacer()
        }
        .frame(width: 180)
        .background(colors.surface)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "eye")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(colors.textPrimary)
            Text("WatchTower")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(colors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }

    private func sidebarTab(_ tab: TabType) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .regular))
                Spacer()
            }
            .foregroundStyle(selectedTab == tab ? colors.textPrimary : colors.textSecondary)
            .frame(height: 34)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == tab ? Color(white: 0.5).opacity(0.08) : .clear)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch selectedTab {
            case .dashboard:
                DashboardView()
            case .accounts:
                AccountsView()
            case .processes:
                ProcessesDetailView()
            case .settings:
                SettingsContentView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsContentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GeneralSettingsSection()
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}

struct GeneralSettingsSection: View {
    @Environment(AppState.self) var state

    var body: some View {
        VStack(spacing: 0) {
            sectionHeader("General")
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                settingRow {
                    Text("Refresh Interval")
                    Spacer()
                    Picker("", selection: Bindable(state).refreshInterval) {
                        Text("1 min").tag(60.0)
                        Text("2 min").tag(120.0)
                        Text("5 min").tag(300.0)
                        Text("10 min").tag(600.0)
                        Text("30 min").tag(1800.0)
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
                Separator()
                settingRow {
                    Text("Monitor Processes")
                    Spacer()
                    Toggle("", isOn: Bindable(state).processesEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
                Separator()
                settingRow {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                }
            }
            .background(.quaternary.opacity(0.15))
            .cornerRadius(8)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
            Spacer()
        }
    }

    private func settingRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack {
            content()
        }
        .frame(height: 36)
        .padding(.horizontal, 12)
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
