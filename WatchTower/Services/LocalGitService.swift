import Foundation

struct LocalGitInfo {
    let branch: String
    let commitHash: String
    let commitMessage: String
    let commitTime: String
    let commitAuthor: String
    let isDirty: Bool
    let ahead: Int
    let behind: Int
}

enum LocalGitService {
    nonisolated static func fetch(repoPath: String) -> LocalGitInfo? {
        let branch = runGit(repoPath, "branch", "--show-current") ?? "?"
        let commitHash = (runGit(repoPath, "log", "-1", "--format=%h") ?? "?").prefix(7).description
        let commitMessage = runGit(repoPath, "log", "-1", "--format=%s") ?? "?"
        let commitTime = runGit(repoPath, "log", "-1", "--format=%ar") ?? "?"
        let commitAuthor = runGit(repoPath, "log", "-1", "--format=%an") ?? "?"
        let status = runGit(repoPath, "status", "--porcelain") ?? ""
        let isDirty = !status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let aheadBehind = runGit(repoPath, "rev-list", "--count", "--left-right", "HEAD...@{upstream}")
        var ahead = 0, behind = 0
        if let ab = aheadBehind {
            let parts = ab.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\t")
            if parts.count == 2 {
                ahead = Int(parts[0]) ?? 0
                behind = Int(parts[1]) ?? 0
            }
        }

        return LocalGitInfo(
            branch: branch,
            commitHash: String(commitHash),
            commitMessage: commitMessage,
            commitTime: commitTime,
            commitAuthor: commitAuthor,
            isDirty: isDirty,
            ahead: ahead,
            behind: behind
        )
    }

    private nonisolated static let gitPaths = [
        "/usr/bin/git",
        "/usr/local/bin/git",
        "/opt/homebrew/bin/git",
    ]

    private nonisolated static func findGit() -> String? {
        for p in gitPaths {
            if FileManager.default.fileExists(atPath: p) { return p }
        }
        return nil
    }

    private nonisolated static func runGit(_ repoPath: String, _ args: String...) -> String? {
        guard let git = findGit() else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: git)
        process.arguments = ["-C", repoPath] + args

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
