import Foundation

enum GitHubService {
    static func fetch(token: String, repos: [String]) async throws -> [StatusItemModel] {
        try await withThrowingTaskGroup(of: StatusItemModel.self) { group in
            for repo in repos {
                group.addTask {
                    try await fetchRepoStatus(token: token, repo: repo)
                }
            }
            var results: [StatusItemModel] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    private static func fetchRepoStatus(token: String, repo: String) async throws -> StatusItemModel {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/actions/runs?per_page=1&status=completed") else {
            return StatusItemModel(
                id: repo, title: repo, subtitle: "Ошибка URL",
                status: .neutral, icon: nil, actionURL: nil
            )
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return StatusItemModel(
                id: repo, title: repo, subtitle: "Нет доступа",
                status: .neutral, icon: nil, actionURL: "https://github.com/\(repo)/actions"
            )
        }

        let decoded = try JSONDecoder().decode(GitHubResponse.self, from: data)
        let latestRun = decoded.workflowRuns.first

        switch latestRun?.conclusion {
        case "success":
            return StatusItemModel(
                id: repo, title: repo, subtitle: "✓ Все проверки пройдены",
                status: .success, icon: nil, actionURL: "https://github.com/\(repo)/actions"
            )
        case "failure":
            return StatusItemModel(
                id: repo, title: repo, subtitle: "✗ Проверки упали",
                status: .danger, icon: nil, actionURL: "https://github.com/\(repo)/actions"
            )
        default:
            return StatusItemModel(
                id: repo, title: repo, subtitle: "Нет завершённых",
                status: .neutral, icon: nil, actionURL: "https://github.com/\(repo)/actions"
            )
        }
    }
}

private struct GitHubResponse: Codable {
    let workflowRuns: [GitHubRun]

    enum CodingKeys: String, CodingKey {
        case workflowRuns = "workflow_runs"
    }
}

private struct GitHubRun: Codable {
    let conclusion: String?
}
