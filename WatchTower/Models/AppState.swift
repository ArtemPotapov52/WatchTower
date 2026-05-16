import SwiftUI
import Observation

@Observable
final class AppState {
    var accounts: [ServiceAccount] = [] { didSet { saveAccounts() } }
    var sectionStates: [String: SectionState] = [:]
    var sectionItems: [String: [StatusItemModel]] = [:]
    var localGitItems: [String: [StatusItemModel]] = [:]
    var processes: [StatusItemModel] = []
    var lastUpdated: Date?
    var isRefreshing = false
    var processesEnabled = true { didSet { saveSetting("processesEnabled", processesEnabled) } }
    var refreshInterval: TimeInterval = 300 { didSet { saveSetting("refreshInterval", refreshInterval) } }
    var colorSchemePreference: String = "system" { didSet { saveSetting("colorSchemePreference", colorSchemePreference) } }

    var hasProblems: Bool {
        sectionStates.values.contains(where: {
            if case .warning = $0 { return true }
            if case .error = $0 { return true }
            return false
        })
    }

    var allSections: [StatusSection] {
        var result: [StatusSection] = []
        for account in accounts {
            let id = account.id.uuidString
            let state: SectionState
            let items: [StatusItemModel]

            if !account.isEnabled {
                let localItems = localGitItems[id] ?? []
                if !localItems.isEmpty {
                    items = localItems
                    state = localItems.contains(where: { $0.status == .danger || $0.status == .warning }) ? .warning : .ok
                } else if account.token.isEmpty {
                    items = []
                    state = .error("Нужен токен")
                } else {
                    items = []
                    state = .error("Отключено")
                }
            } else {
                let remoteItems = sectionItems[id] ?? []
                if !remoteItems.isEmpty || account.textValues["localPath"] == nil {
                    items = remoteItems
                    state = sectionStates[id] ?? .ok
                } else {
                    let localItems = localGitItems[id] ?? []
                    items = localItems
                    state = localItems.contains(where: { $0.status == .danger || $0.status == .warning }) ? .warning : .ok
                }
            }

            result.append(StatusSection(
                id: id,
                name: account.name,
                icon: account.serviceType.icon,
                state: state,
                items: items
            ))
        }
        result.append(StatusSection(
            id: "processes",
            name: "Процессы",
            icon: "cpu",
            state: .ok,
            items: processes
        ))
        return result
    }

    private let defaults = UserDefaults.standard
    private var refreshTask: Task<Void, Never>?
    private var processesTask: Task<Void, Never>?

    init() {
        loadAccounts()
        loadSettings()
        Task { await refreshLocalGit() }
        Task { await runAutoDiscovery() }
        startRefreshTimer()
        startProcessesMonitor()
    }

    func refreshAll() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let remoteAccounts = accounts.filter { a in
            a.isEnabled && (a.textValues["localPath"] == nil || !a.token.isEmpty)
        }
        for account in remoteAccounts {
            sectionStates[account.id.uuidString] = .loading
        }

        await withTaskGroup(of: Void.self) { group in
            for account in remoteAccounts {
                group.addTask { await self.refreshAccount(account) }
            }
        }

        lastUpdated = Date()
    }

    func refreshAccount(_ account: ServiceAccount) async {
        let id = account.id.uuidString
        do {
            let items = try await fetchForAccount(account)
            let hasIssues = items.contains { $0.status == .danger || $0.status == .warning }
            setSection(id: id, state: hasIssues ? .warning : .ok, items: items)
        } catch {
            setSection(id: id, state: .error("Ошибка"), items: [])
        }
    }

    private func fetchForAccount(_ account: ServiceAccount) async throws -> [StatusItemModel] {
        switch account.serviceType {
        case .github:
            let repos = account.listValues["repos"] ?? []
            return try await GitHubService.fetch(token: account.token, repos: repos)
        case .gitlab:
            let repos = account.listValues["repos"] ?? []
            let url = account.textValues["url"] ?? "https://gitlab.com"
            return try await GitLabService.fetch(token: account.token, baseURL: url, projects: repos)
        case .vercel:
            let projects = account.listValues["projects"] ?? []
            return try await VercelService.fetch(token: account.token, projects: projects)
        case .netlify:
            let sites = account.listValues["sites"] ?? []
            return try await NetlifyService.fetch(token: account.token, sites: sites)
        case .sentry:
            let org = account.textValues["org"] ?? ""
            let project = account.textValues["project"] ?? ""
            return try await SentryService.fetch(token: account.token, org: org, project: project)
        case .datadog:
            let site = account.textValues["site"] ?? "datadoghq.com"
            return try await DatadogService.fetch(apiKey: account.token, appKey: account.extraToken, site: site)
        case .uptime:
            let urls = account.listValues["urls"] ?? []
            return try await UptimeService.fetch(urls: urls)
        case .railway:
            let projects = account.listValues["projects"] ?? []
            return try await RailwayService.fetch(token: account.token, projects: projects)
        case .custom:
            let checks = account.listValues["checks"] ?? []
            let configs = checks.map { parseCustomCheck($0) }
            return await CustomService.runChecks(configs)
        }
    }

    private nonisolated func parseCustomCheck(_ input: String) -> [String: String] {
        let parts = input.split(separator: ":", maxSplits: 2).map(String.init)
        guard parts.count == 3 else { return ["name": input, "type": "http", "target": input, "expected": "200"] }
        return ["type": parts[0], "target": parts[1], "expected": parts[2], "name": input]
    }

    func addAccount(_ account: ServiceAccount) {
        accounts.append(account)
        Task { await refreshAccount(account) }
    }

    func deleteAccount(_ account: ServiceAccount) {
        accounts.removeAll { $0.id == account.id }
        sectionStates.removeValue(forKey: account.id.uuidString)
        sectionItems.removeValue(forKey: account.id.uuidString)
    }

    func updateAccount(_ account: ServiceAccount) {
        guard let index = accounts.firstIndex(where: { $0.id == account.id }) else { return }
        accounts[index] = account
        Task { await refreshAccount(account) }
    }

    // MARK: - Processes

    // MARK: - Auto Discovery

    var discoveredRepos: [DiscoveredRepo] = []
    var discoveredDotfiles: [DiscoveredRepo] = []
    var gitUserName: String? = nil
    var hasRunAutoDiscovery = false
    var popupFilter: String? = nil

    var popupFilterOptions: [String] {
        var types = Array(Set(accounts.map { $0.serviceType.rawValue })).sorted()
        if !processes.isEmpty || processesEnabled { types.insert("Процессы", at: 0) }
        return ["All"] + types
    }

    var filteredSections: [StatusSection] {
        let all = allSections
        guard let filter = popupFilter, filter != "All" else { return all }
        if filter == "Процессы" {
            return all.filter { $0.id == "processes" }
        }
        return all.filter { section in
            accounts.contains { $0.id.uuidString == section.id && $0.serviceType.rawValue == filter }
        }
    }

    func runAutoDiscovery() async {
        guard !hasRunAutoDiscovery else { return }
        hasRunAutoDiscovery = true

        let repos = await Task.detached {
            SystemScanner.scanForGitRepos()
        }.value
        let dots = await Task.detached {
            SystemScanner.scanForDotfiles()
        }.value
        let gitUser = await Task.detached {
            SystemScanner.scanForGitHubUser()
        }.value

        await MainActor.run {
            discoveredRepos = repos
            discoveredDotfiles = dots
            gitUserName = gitUser

            for repo in repos {
                let type = repo.serviceType
                if let existingIndex = accounts.firstIndex(where: { a in
                    (a.listValues["repos"] ?? []).contains(repo.fullName)
                }) {
                    if accounts[existingIndex].textValues["localPath"]?.isEmpty ?? true {
                        accounts[existingIndex].textValues["localPath"] = repo.path
                    }
                } else {
                    var account = ServiceAccount.empty(type)
                    account.name = repo.fullName
                    account.listValues["repos"] = [repo.fullName]
                    account.textValues["localPath"] = repo.path
                    account.isEnabled = false
                    accounts.insert(account, at: 0)
                }
            }
        }
        await refreshLocalGit()
    }

    func refreshLocalGit() async {
        let matching = accounts.filter { !($0.textValues["localPath"] ?? "").isEmpty }
        guard !matching.isEmpty else { return }

        let updated = await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                var result: [String: [StatusItemModel]] = [:]
                for account in matching {
                    let path = account.textValues["localPath"]!
                    let id = account.id.uuidString
                    let info = LocalGitService.fetch(repoPath: path)
                    guard let info else { continue }
                    var items: [StatusItemModel] = [
                        StatusItemModel(
                            id: "\(id)-branch",
                            title: info.branch + (info.isDirty ? " ●" : ""),
                            subtitle: info.commitHash,
                            status: info.isDirty ? .warning : .success,
                            icon: "arrow.triangle.branch",
                            actionURL: nil
                        ),
                        StatusItemModel(
                            id: "\(id)-commit",
                            title: info.commitMessage,
                            subtitle: "\(info.commitAuthor) · \(info.commitTime)",
                            status: .neutral,
                            icon: "message",
                            actionURL: nil
                        ),
                    ]
                    if info.ahead > 0 || info.behind > 0 {
                        var subtitle = ""
                        if info.ahead > 0 { subtitle += "+\(info.ahead)" }
                        if info.behind > 0 { subtitle += subtitle.isEmpty ? "" : " " ; subtitle += "-\(info.behind)" }
                        items.append(StatusItemModel(
                            id: "\(id)-sync",
                            title: "Относительно remote",
                            subtitle: subtitle,
                            status: info.behind > 0 ? .warning : .success,
                            icon: "arrow.triangle.2.circlepath",
                            actionURL: nil
                        ))
                    }
                    result[id] = items
                }
                continuation.resume(returning: result)
            }
        }
        localGitItems = updated
    }

    // MARK: - Processes

    private func startProcessesMonitor() {
        processesTask?.cancel()
        processesTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.processesEnabled else {
                    try? await Task.sleep(for: .seconds(15))
                    continue
                }
                let items = ProcessMonitor.topProcesses()
                await MainActor.run { self.processes = items }
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }

    // MARK: - Timer

    private func startRefreshTimer() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(self?.refreshInterval ?? 300))
                await self?.refreshAll()
                await self?.refreshLocalGit()
            }
        }
    }

    // MARK: - Persistence

    private func saveAccounts() {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        defaults.set(data, forKey: "accounts")
    }

    private func loadAccounts() {
        guard let data = defaults.data(forKey: "accounts"),
              let decoded = try? JSONDecoder().decode([ServiceAccount].self, from: data) else {
            accounts = []
            return
        }
        accounts = decoded
    }

    private func saveSetting<T: Codable>(_ key: String, _ value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func loadSettings() {
        if let data = defaults.data(forKey: "processesEnabled"),
           let val = try? JSONDecoder().decode(Bool.self, from: data) {
            processesEnabled = val
        }
        if let data = defaults.data(forKey: "refreshInterval"),
           let val = try? JSONDecoder().decode(TimeInterval.self, from: data) {
            refreshInterval = val
        }
        if let data = defaults.data(forKey: "colorSchemePreference"),
           let val = try? JSONDecoder().decode(String.self, from: data) {
            colorSchemePreference = val
        }
    }

    @MainActor
    private func setSection(id: String, state: SectionState, items: [StatusItemModel]) {
        sectionStates[id] = state
        sectionItems[id] = items
    }
}
