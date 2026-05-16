import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppState.self) var state

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                generalSection
                aboutSection
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(colors.background)
    }

    private var generalSection: some View {
        VStack(spacing: 0) {
            sectionHeader("GENERAL")
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                settingsRow {
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
                settingsRow {
                    Text("Monitor Processes")
                    Spacer()
                    Toggle("", isOn: Bindable(state).processesEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
                Separator()
                settingsRow {
                    Text("Theme")
                    Spacer()
                    Picker("", selection: Bindable(state).colorSchemePreference) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .labelsHidden()
                    .frame(width: 120)
                }
            }
            .background(.quaternary.opacity(0.15))
            .cornerRadius(8)
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 0) {
            sectionHeader("ABOUT")
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                settingsRow {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                }
                Separator()
                settingsRow {
                    Text("Build")
                    Spacer()
                    Text("1")
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
            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.tertiary)
                .tracking(0.5)
            Spacer()
        }
    }

    private func settingsRow<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        HStack {
            content()
        }
        .frame(height: 36)
        .padding(.horizontal, 12)
    }
}

struct SettingRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(height: 36)
        .padding(.horizontal, 12)
    }
}
