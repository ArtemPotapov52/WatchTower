import Foundation

enum ProcessMonitor {
    static func topProcesses() -> [StatusItemModel] {
        let username = NSUserName()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-u", username, "-o", "pid,pcpu,comm", "-r"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        return parsePSOutput(output)
    }

    private static func parsePSOutput(_ output: String) -> [StatusItemModel] {
        let lines = output.components(separatedBy: .newlines)
        guard lines.count > 1 else { return [] }

        var processes: [(cpu: Double, name: String, pid: String)] = []

        for line in lines.dropFirst().prefix(20) {
            let parts = line.split(separator: " ", omittingEmptySubsequences: true)
            guard parts.count >= 3 else { continue }

            let cpuStr = String(parts[1]).replacingOccurrences(of: ",", with: ".")
            guard let cpu = Double(cpuStr) else { continue }

            let pid = String(parts[0])
            let name = parts.dropFirst(2).joined(separator: " ")

            processes.append((cpu, name, pid))
        }

        processes.sort { $0.cpu > $1.cpu }

        return processes.prefix(5).map { proc in
            StatusItemModel(
                id: proc.pid,
                title: URL(fileURLWithPath: proc.name).lastPathComponent,
                subtitle: String(format: "%.1f%%", proc.cpu),
                status: proc.cpu > 50 ? .warning : .neutral,
                icon: nil,
                actionURL: nil
            )
        }
    }
}
