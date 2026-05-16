import Foundation

struct DiscoveredRepo: Identifiable {
    let id: String
    let path: String
    let fullName: String
    let serviceType: ServiceType
    let remoteURL: String

    var displayName: String { fullName }
}

struct SystemScanner {
    nonisolated static let searchDirs: [String] = [
        "Developer", "dev", "projects", "code", "github", "src", "work", "repos",
        "Desktop", "Documents", ".dotfiles", "go/src", "oss", "playground",
        "sandbox", "tools", "apps", "sites", "lab", "test", "tmp",
        "trae_projects", "Downloads", "free-claude-code",
    ]

    nonisolated static func scanForGitRepos() -> [DiscoveredRepo] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var found: [DiscoveredRepo] = []

        for dir in searchDirs {
            let path = home.appendingPathComponent(dir)
            guard FileManager.default.fileExists(atPath: path.path) else { continue }
            scanDir(path.path, depth: 0, maxDepth: 3, results: &found)
        }

        scanDir(home.path, depth: 0, maxDepth: 2, results: &found)

        var seen = Set<String>()
        return found.filter { seen.insert($0.id).inserted }.sorted { $0.fullName < $1.fullName }
    }

    nonisolated static func scanForGitHubUser() -> String? {
        let configPaths = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gitconfig").path,
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/git/config").path,
        ]
        for configPath in configPaths {
            guard let data = try? String(contentsOfFile: configPath) else { continue }
            let lines = data.components(separatedBy: .newlines)
            var user = "", separatorFound = false
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed == "[user]" { separatorFound = true; continue }
                if separatorFound, trimmed.hasPrefix("name = ") {
                    user = String(trimmed.dropFirst(6))
                    break
                }
                if separatorFound, trimmed.hasPrefix("[") && !trimmed.hasPrefix("[user") {
                    break
                }
            }
            if !user.isEmpty { return user }
        }
        return nil
    }

    nonisolated static func scanForDotfiles() -> [DiscoveredRepo] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let dotDirs = [".vercel", ".netlify"]
        return dotDirs.compactMap { dir in
            let path = home.appendingPathComponent(dir)
            guard FileManager.default.fileExists(atPath: path.path) else { return nil }
            return DiscoveredRepo(
                id: dir,
                path: path.path,
                fullName: dir,
                serviceType: dir == ".vercel" ? .vercel : .netlify,
                remoteURL: path.path
            )
        }
    }

    nonisolated static func detectVercel() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configPath = home.appendingPathComponent(".vercel/config.json")
        return FileManager.default.fileExists(atPath: configPath.path)
    }

    nonisolated static func detectNetlify() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let statePath = home.appendingPathComponent(".netlify/state.json")
        return FileManager.default.fileExists(atPath: statePath.path)
    }

    nonisolated static func hasCLI(_ name: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus == 0
    }

    // MARK: - Private

    private nonisolated static func scanDir(_ path: String, depth: Int, maxDepth: Int, results: inout [DiscoveredRepo]) {
        guard depth <= maxDepth else { return }
        let gitPath = (path as NSString).appendingPathComponent(".git")
        if FileManager.default.fileExists(atPath: gitPath) {
            if let repo = parseRepo(path: path) {
                results.append(repo)
            }
            return
        }

        guard depth < maxDepth else { return }
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else { return }

        for item in contents {
            guard !item.hasPrefix(".") else { continue }
            let itemPath = (path as NSString).appendingPathComponent(item)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir), isDir.boolValue else { continue }
            scanDir(itemPath, depth: depth + 1, maxDepth: maxDepth, results: &results)
        }
    }

    private nonisolated static func parseRepo(path: String) -> DiscoveredRepo? {
        let gitConfigPath = (path as NSString).appendingPathComponent(".git/config")
        guard let config = try? String(contentsOfFile: gitConfigPath) else { return nil }

        let lines = config.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("url = ") {
                let url = String(trimmed.dropFirst(6))
                if let fullName = parseGitURL(url) {
                    let type: ServiceType = url.contains("gitlab") ? .gitlab : .github
                    return DiscoveredRepo(
                        id: fullName,
                        path: path,
                        fullName: fullName,
                        serviceType: type,
                        remoteURL: url
                    )
                }
            }
        }
        return nil
    }

    nonisolated static func parseGitURL(_ url: String) -> String? {
        let cleanURL = url.trimmingCharacters(in: .whitespaces)

        // ssh: git@github.com:user/repo.git
        if cleanURL.contains("github.com:") {
            if let range = cleanURL.range(of: "github.com:") {
                return cleanURL[range.upperBound...]
                    .replacingOccurrences(of: ".git", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/ \n"))
            }
        }
        if cleanURL.contains("gitlab.com:") {
            if let range = cleanURL.range(of: "gitlab.com:") {
                return cleanURL[range.upperBound...]
                    .replacingOccurrences(of: ".git", with: "")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "/ \n"))
            }
        }

        // https/git/ssh: github.com/user/repo.git
        for domain in ["github.com/", "gitlab.com/"] {
            if cleanURL.contains(domain) {
                if let range = cleanURL.range(of: domain) {
                    let suffix = String(cleanURL[range.upperBound...])
                    let parts = suffix.split(separator: "/")
                    if parts.count >= 2 {
                        let name = parts.dropLast().joined(separator: "/") + "/" + parts.last!
                            .replacingOccurrences(of: ".git", with: "")
                        if !name.contains("/") { continue }
                        return name
                    }
                }
            }
        }

        return nil
    }
}
