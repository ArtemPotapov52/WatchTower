import SwiftUI

struct ProcessesDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(AppState.self) var state

    private var colors: AppColors { AppColors.forScheme(colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Separator()
            processList
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("System Processes")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(colors.textPrimary)
                Text("Top processes by CPU usage · Updates every 15s")
                    .font(.system(size: 11))
                    .foregroundStyle(colors.textTertiary)
            }
            Spacer()

            if state.processesEnabled {
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppColors.success)
                        .frame(width: 5, height: 5)
                    Text("Monitoring")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.success)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppColors.success.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var processList: some View {
        VStack(spacing: 0) {
            tableHeader

            if state.processes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(state.processes.enumerated()), id: \.offset) { _, proc in
                            processRow(proc)
                        }
                    }
                }
            }
        }
    }

    private var tableHeader: some View {
        HStack(spacing: 0) {
            Text("Process")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)
            Text("PID")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(colors.textTertiary)
                .frame(width: 60, alignment: .trailing)
            Text("CPU")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(colors.textTertiary)
                .frame(width: 70, alignment: .trailing)
                .padding(.trailing, 24)
        }
        .frame(height: 28)
        .background(colors.surface)
    }

    private func processRow(_ proc: StatusItemModel) -> some View {
        HStack(spacing: 0) {
            Text(proc.title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(colors.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 24)

            Text(proc.id)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(colors.textTertiary)
                .frame(width: 60, alignment: .trailing)

            HStack(spacing: 6) {
                let cpuText = proc.subtitle?.replacingOccurrences(of: " CPU", with: "") ?? ""
                Text(cpuText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(proc.status == .warning ? AppColors.warning : colors.textPrimary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.quaternary.opacity(0.3))
                            .frame(width: geo.size.width, height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(proc.status == .warning ? AppColors.warning : AppColors.success)
                            .frame(width: min(cpuBarWidth(geo.size.width, cpuText: cpuText), geo.size.width), height: 4)
                    }
                }
                .frame(width: 40)
            }
            .frame(width: 100, alignment: .trailing)
            .padding(.trailing, 24)
        }
        .frame(height: 36)
    }

    private func cpuBarWidth(_ totalWidth: CGFloat, cpuText: String) -> CGFloat {
        let cleaned = cpuText.replacingOccurrences(of: " CPU", with: "").replacingOccurrences(of: "%", with: "")
        guard let cpu = Double(cleaned), cpu > 0 else { return 0 }
        return totalWidth * CGFloat(cpu / 100)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "cpu")
                .font(.system(size: 24))
                .foregroundStyle(colors.textTertiary)
            Text(state.processesEnabled ? "Waiting for data..." : "Process monitoring is disabled")
                .font(.system(size: 12))
                .foregroundStyle(colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
