import Foundation

enum NetlifyService {
    static func fetch(token: String, sites: [String]) async throws -> [StatusItemModel] {
        try await withThrowingTaskGroup(of: StatusItemModel.self) { group in
            for site in sites {
                group.addTask {
                    try await fetchSiteStatus(token: token, siteID: site)
                }
            }
            var results: [StatusItemModel] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    private static func fetchSiteStatus(token: String, siteID: String) async throws -> StatusItemModel {
        guard let url = URL(string: "https://api.netlify.com/api/v1/sites/\(siteID)/deploys?per_page=1") else {
            return StatusItemModel(id: siteID, title: siteID, subtitle: "Ошибка URL", status: .neutral, icon: nil, actionURL: nil)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return StatusItemModel(id: siteID, title: siteID, subtitle: "Нет доступа", status: .neutral, icon: nil, actionURL: nil)
        }

        let deploys = try JSONDecoder().decode([NetlifyDeploy].self, from: data)
        guard let latest = deploys.first else {
            return StatusItemModel(id: siteID, title: siteID, subtitle: "Нет деплоев", status: .neutral, icon: nil, actionURL: nil)
        }

        let status: StatusType = latest.state == "ready" ? .success : .danger
        return StatusItemModel(id: siteID, title: siteID,
                             subtitle: status == .success ? "✓ Опубликован" : "✗ \(latest.state)",
                             status: status, icon: nil, actionURL: latest.url)
    }
}

private struct NetlifyDeploy: Codable {
    let state: String
    let url: String?
}
