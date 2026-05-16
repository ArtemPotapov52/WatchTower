import Foundation

enum SentryService {
    static func fetch(token: String, org: String, project: String) async throws -> [StatusItemModel] {
        let orgEncoded = org.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? org
        let projectEncoded = project.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? project
        guard let url = URL(string: "https://sentry.io/api/0/projects/\(orgEncoded)/\(projectEncoded)/issues/?statsPeriod=24h&query=is:unresolved") else {
            return [StatusItemModel(id: "error", title: "Ошибка URL", subtitle: nil, status: .neutral, icon: nil, actionURL: nil)]
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return [StatusItemModel(
                id: "error", title: "Нет доступа", subtitle: nil,
                status: .neutral, icon: nil, actionURL: nil
            )]
        }

        let issues = try JSONDecoder().decode([SentryIssue].self, from: data)
        guard !issues.isEmpty else {
            return [StatusItemModel(
                id: "all-clear", title: "Нет новых ошибок", subtitle: nil,
                status: .success, icon: nil, actionURL: nil
            )]
        }

        return issues.prefix(5).map { issue in
            StatusItemModel(
                id: issue.id,
                title: issue.title,
                subtitle: "\(issue.count) вх. · \(issue.level)",
                status: issue.level == "error" || issue.level == "fatal" ? .danger : .warning,
                icon: nil,
                actionURL: "https://sentry.io/organizations/\(org)/issues/\(issue.id)/"
            )
        }
    }
}

private struct SentryIssue: Codable {
    let id: String
    let title: String
    let count: Int
    let level: String

    enum CodingKeys: String, CodingKey {
        case id, title, count, level
    }
}
