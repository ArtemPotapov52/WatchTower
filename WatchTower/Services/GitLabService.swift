import Foundation

enum GitLabService {
    static func fetch(token: String, baseURL: String, projects: [String]) async throws -> [StatusItemModel] {
        try await withThrowingTaskGroup(of: StatusItemModel.self) { group in
            for project in projects {
                group.addTask {
                    try await fetchProjectStatus(token: token, baseURL: baseURL, project: project)
                }
            }
            var results: [StatusItemModel] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    private static func fetchProjectStatus(token: String, baseURL: String, project: String) async throws -> StatusItemModel {
        let encoded = project.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? project
        guard let url = URL(string: "\(baseURL)/api/v4/projects/\(encoded)/pipelines?per_page=1") else {
            return StatusItemModel(id: project, title: project, subtitle: "Ошибка URL",
                                 status: .neutral, icon: nil, actionURL: nil)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return StatusItemModel(id: project, title: project, subtitle: "Нет доступа",
                                 status: .neutral, icon: nil, actionURL: "\(baseURL)/\(project)/-/pipelines")
        }

        let pipelines = try JSONDecoder().decode([GitLabPipeline].self, from: data)
        guard let latest = pipelines.first else {
            return StatusItemModel(id: project, title: project, subtitle: "Нет пайплайнов",
                                 status: .neutral, icon: nil, actionURL: "\(baseURL)/\(project)/-/pipelines")
        }

        let status: StatusType = latest.status == "success" ? .success :
                                 latest.status == "running" || latest.status == "pending" ? .warning :
                                 latest.status == "canceled" || latest.status == "skipped" ? .neutral : .danger
        let subtitle: String = {
            switch latest.status {
            case "success": return "✓ Успешно"
            case "running": return "⟳ Выполняется"
            case "pending": return "⟳ Ожидает"
            case "failed": return "✗ Упал"
            case "canceled": return "— Отменён"
            case "skipped": return "— Пропущен"
            default: return "? \(latest.status)"
            }
        }()
        return StatusItemModel(id: project, title: project, subtitle: subtitle,
                             status: status, icon: nil,
                             actionURL: "\(baseURL)/\(project)/-/pipelines")
    }
}

private struct GitLabPipeline: Codable {
    let status: String
}
