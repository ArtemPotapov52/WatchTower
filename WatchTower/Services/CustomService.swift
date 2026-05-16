import Foundation

struct CustomCheckResult {
    let name: String
    let success: Bool
    let message: String
}

enum CustomService {
    nonisolated static func runChecks(_ checks: [[String: String]]) async -> [StatusItemModel] {
        await withTaskGroup(of: StatusItemModel.self) { group in
            for check in checks {
                group.addTask {
                    await runCheck(check)
                }
            }
            var results: [StatusItemModel] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    private nonisolated static func runCheck(_ config: [String: String]) async -> StatusItemModel {
        let name = config["name"] ?? "Check"
        let type = config["type"] ?? "http"
        let target = config["target"] ?? ""
        let expected = config["expected"] ?? "200"

        switch type {
        case "http", "https":
            return await checkHTTP(name: name, url: target, expectedCode: Int(expected) ?? 200)
        case "ping":
            return await checkPing(name: name, host: target)
        case "port":
            return await checkPort(name: name, host: target, port: Int(expected) ?? 80)
        case "script":
            return await runScript(name: name, command: target)
        default:
            return StatusItemModel(id: name, title: name, subtitle: "Unknown check type", status: .neutral, icon: nil, actionURL: nil)
        }
    }

    private nonisolated static func checkHTTP(name: String, url: String, expectedCode: Int) async -> StatusItemModel {
        guard let url = URL(string: url) else {
            return StatusItemModel(id: name, title: name, subtitle: "Bad URL", status: .danger, icon: nil, actionURL: nil)
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 10

        let start = Date()
        guard let (_, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse else {
            return StatusItemModel(id: name, title: name, subtitle: "Unreachable", status: .danger, icon: nil, actionURL: url.absoluteString)
        }

        let ms = Int(Date().timeIntervalSince(start) * 1000)
        let ok = (200..<400).contains(http.statusCode)
        return StatusItemModel(
            id: name, title: name,
            subtitle: ok ? "\(http.statusCode) · \(ms)ms" : "\(http.statusCode)",
            status: ok ? .success : .danger,
            icon: nil, actionURL: url.absoluteString
        )
    }

    private nonisolated static func checkPing(name: String, host: String) async -> StatusItemModel {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-t", "5", host]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        let start = Date()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return StatusItemModel(id: name, title: name, subtitle: "Ping failed", status: .danger, icon: nil, actionURL: nil)
        }

        let ms = Int(Date().timeIntervalSince(start) * 1000)
        return StatusItemModel(
            id: name, title: name,
            subtitle: process.terminationStatus == 0 ? "\(ms)ms" : "Timeout",
            status: process.terminationStatus == 0 ? .success : .danger,
            icon: nil, actionURL: nil
        )
    }

    private nonisolated static func checkPort(name: String, host: String, port: Int) async -> StatusItemModel {
        return await Task.detached {
            var hint = addrinfo()
            hint.ai_family = AF_INET
            hint.ai_socktype = SOCK_STREAM

            var addrList: UnsafeMutablePointer<addrinfo>?
            let res = getaddrinfo(host, nil, &hint, &addrList)
            guard res == 0, let list = addrList else {
                return StatusItemModel(id: name, title: name, subtitle: "Host not found", status: .danger, icon: nil, actionURL: nil)
            }
            defer { freeaddrinfo(addrList) }

            let remoteAddr = list.pointee
            guard let sa = remoteAddr.ai_addr else {
                return StatusItemModel(id: name, title: name, subtitle: "No address", status: .danger, icon: nil, actionURL: nil)
            }

            let sin = UnsafeMutableRawPointer(sa).assumingMemoryBound(to: sockaddr_in.self)
            sin.pointee.sin_port = UInt16(port).bigEndian

            let sock = socket(AF_INET, SOCK_STREAM, 0)
            guard sock >= 0 else {
                return StatusItemModel(id: name, title: name, subtitle: "Socket error", status: .danger, icon: nil, actionURL: nil)
            }
            defer { close(sock) }

            var timeout = timeval(tv_sec: 5, tv_usec: 0)
            setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))

            let start = Date()
            let result = Darwin.connect(sock, sa, remoteAddr.ai_addrlen)

            let ms = Int(Date().timeIntervalSince(start) * 1000)
            return StatusItemModel(
                id: name, title: name,
                subtitle: result == 0 ? "Open · \(ms)ms" : "Closed",
                status: result == 0 ? .success : .danger,
                icon: nil, actionURL: nil
            )
        }.value
    }

    private nonisolated static func runScript(name: String, command: String) async -> StatusItemModel {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return StatusItemModel(id: name, title: name, subtitle: "Failed", status: .danger, icon: nil, actionURL: nil)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return StatusItemModel(
            id: name, title: name,
            subtitle: process.terminationStatus == 0 ? (output.isEmpty ? "OK" : output) : "Exit \(process.terminationStatus)",
            status: process.terminationStatus == 0 ? .success : .danger,
            icon: nil, actionURL: nil
        )
    }
}
