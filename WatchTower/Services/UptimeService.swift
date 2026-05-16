import Foundation

enum UptimeService {
    static func fetch(urls: [String]) async throws -> [StatusItemModel] {
        try await withThrowingTaskGroup(of: StatusItemModel.self) { group in
            for urlString in urls {
                group.addTask {
                    await checkURL(urlString)
                }
            }
            var results: [StatusItemModel] = []
            for try await result in group {
                results.append(result)
            }
            return results.sorted { $0.title < $1.title }
        }
    }

    private static func checkURL(_ urlString: String) async -> StatusItemModel {
        guard let url = URL(string: urlString) else {
            return StatusItemModel(
                id: urlString, title: urlString, subtitle: "Неверный URL",
                status: .danger, icon: nil, actionURL: urlString
            )
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.httpMethod = "HEAD"

        let start = Date()
        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse else {
            return StatusItemModel(
                id: urlString, title: urlString, subtitle: "Недоступен",
                status: .danger, icon: nil, actionURL: urlString
            )
        }

        let ms = Int(Date().timeIntervalSince(start) * 1000)
        let isOK = (200..<400).contains(httpResponse.statusCode)
        let displayURL = url.host ?? urlString

        return StatusItemModel(
            id: urlString, title: displayURL,
            subtitle: isOK ? "\(httpResponse.statusCode) · \(ms)ms" : "\(httpResponse.statusCode)",
            status: isOK ? .success : .danger,
            icon: nil, actionURL: urlString
        )
    }
}
