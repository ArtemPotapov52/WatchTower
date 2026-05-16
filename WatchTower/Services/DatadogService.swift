import Foundation

enum DatadogService {
    static func fetch(apiKey: String, appKey: String, site: String) async throws -> [StatusItemModel] {
        guard let url = URL(string: "https://api.\(site)/api/v1/monitor") else {
            return [StatusItemModel(id: "error", title: "Datadog", subtitle: "Ошибка URL", status: .neutral, icon: nil, actionURL: nil)]
        }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "DD-API-KEY")
        request.setValue(appKey, forHTTPHeaderField: "DD-APPLICATION-KEY")
        request.timeoutInterval = 8

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return [StatusItemModel(id: "error", title: "Datadog", subtitle: "Нет доступа", status: .neutral, icon: nil, actionURL: nil)]
        }

        var allMonitors = try JSONDecoder().decode([DatadogMonitor].self, from: data)
        if allMonitors.isEmpty {
            return [StatusItemModel(id: "all-clear", title: "Datadog", subtitle: "Нет активных мониторов", status: .success, icon: nil, actionURL: nil)]
        }

        allMonitors.sort { $0.name ?? "" < $1.name ?? "" }
        let filtered = allMonitors.filter { $0.status != "OK" }.prefix(5)
        if filtered.isEmpty {
            return [StatusItemModel(id: "all-ok", title: "Datadog", subtitle: "Все мониторы в порядке", status: .success, icon: nil, actionURL: nil)]
        }

        return filtered.map { monitor in
            let status: StatusType = monitor.status == "Alert" ? .danger : .warning
            return StatusItemModel(id: String(monitor.id), title: monitor.name ?? "Монитор",
                                 subtitle: "Статус: \(monitor.status)",
                                 status: status, icon: nil, actionURL: nil)
        }
    }
}

private struct DatadogMonitor: Codable {
    let id: Int
    let name: String?
    let status: String
}
