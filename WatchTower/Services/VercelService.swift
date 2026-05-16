import Foundation

enum VercelService {
    static func fetch(token: String, projects: [String]) async throws -> [StatusItemModel] {
        try await withThrowingTaskGroup(of: StatusItemModel.self) { group in
            for project in projects {
                group.addTask {
                    try await fetchProjectStatus(token: token, project: project)
                }
            }
            var results: [StatusItemModel] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    private static func fetchProjectStatus(token: String, project: String) async throws -> StatusItemModel {
        guard let encoded = project.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return StatusItemModel(id: project, title: project, subtitle: "Ошибка", status: .neutral, icon: nil, actionURL: nil)
        }
        guard let url = URL(string: "https://api.vercel.com/v6/deployments?projectId=\(encoded)&limit=1") else {
            return StatusItemModel(
                id: project, title: project, subtitle: "Ошибка URL",
                status: .neutral, icon: nil, actionURL: nil
            )
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return StatusItemModel(
                id: project, title: project, subtitle: "Нет доступа",
                status: .neutral, icon: nil, actionURL: nil
            )
        }

        let decoded = try JSONDecoder().decode(VercelResponse.self, from: data)
        let latestDeployment = decoded.deployments.first

        if let deploy = latestDeployment {
            let subtitle = formatDate(deploy.createdAt)
            let status: StatusType = deploy.state == "READY" ? .success :
                                      deploy.state == "ERROR" ? .danger : .warning
            let icon = status == .success ? "✓" : status == .danger ? "✗" : "⟳"
            return StatusItemModel(
                id: project, title: project, subtitle: "\(icon) \(subtitle)",
                status: status, icon: nil,
                actionURL: "https://\(deploy.url ?? "vercel.com")"
            )
        }

        return StatusItemModel(
            id: project, title: project, subtitle: "Нет деплоев",
            status: .neutral, icon: nil, actionURL: "https://vercel.com"
        )
    }

    private static func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000)
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ru")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct VercelResponse: Codable {
    let deployments: [VercelDeployment]
}

private struct VercelDeployment: Codable {
    let url: String?
    let createdAt: Int
    let state: String

    enum CodingKeys: String, CodingKey {
        case url, state
        case createdAt = "createdAt"
    }
}
