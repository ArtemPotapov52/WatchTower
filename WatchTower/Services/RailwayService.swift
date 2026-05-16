import Foundation

enum RailwayService {
    nonisolated static func fetch(token: String, projects: [String]) async throws -> [StatusItemModel] {
        try await withThrowingTaskGroup(of: StatusItemModel.self) { group in
            for project in projects {
                group.addTask {
                    try await fetchProjectStatus(token: token, projectId: project)
                }
            }
            var results: [StatusItemModel] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    private nonisolated static func fetchProjectStatus(token: String, projectId: String) async throws -> StatusItemModel {
        let url = URL(string: "https://api.railway.app/graphql/v2")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8
        request.httpMethod = "POST"

        let query: [String: Any] = [
            "query": "{ project(id: \"\(projectId)\") { name updatedAt deployments(last: 1) { edges { node { id status createdAt } } } } }"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: query)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return StatusItemModel(id: projectId, title: projectId, subtitle: "Нет доступа", status: .neutral, icon: nil, actionURL: nil)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let projectData = (json?["data"] as? [String: Any])?["project"] as? [String: Any]
        let name = projectData?["name"] as? String ?? projectId
        let deployments = (projectData?["deployments"] as? [String: Any])?["edges"] as? [[String: Any]]
        let deploy = deployments?.first?["node"] as? [String: Any]
        let deployStatus = deploy?["status"] as? String ?? "unknown"

        let status: StatusType = deployStatus == "SUCCESS" ? .success :
                                 deployStatus == "FAILED" ? .danger : .warning

        return StatusItemModel(
            id: projectId,
            title: name,
            subtitle: status == .success ? "✓ Deployed" : "✗ \(deployStatus)",
            status: status,
            icon: nil,
            actionURL: "https://railway.app/project/\(projectId)"
        )
    }
}
