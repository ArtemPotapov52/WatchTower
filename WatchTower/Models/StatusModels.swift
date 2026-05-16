import Foundation
import SwiftUI

enum StatusType {
    case success
    case warning
    case danger
    case neutral
}

struct StatusItemModel: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let status: StatusType
    let icon: String?
    let actionURL: String?

    static func == (lhs: StatusItemModel, rhs: StatusItemModel) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.status == rhs.status
    }
}

enum SectionState: Equatable {
    case loading
    case ok
    case warning
    case error(String)
}

struct StatusSection: Identifiable, Equatable {
    let id: String
    let name: String
    let icon: String
    var state: SectionState
    var items: [StatusItemModel]

    static func == (lhs: StatusSection, rhs: StatusSection) -> Bool {
        lhs.id == rhs.id && lhs.state == rhs.state && lhs.items == rhs.items
    }

    var problemCount: Int {
        items.filter { $0.status == .danger || $0.status == .warning }.count
    }

    var okCount: Int {
        items.filter { $0.status == .success }.count
    }

    var totalCount: Int {
        items.count
    }
}

// MARK: - Service Accounts

enum ServiceType: String, CaseIterable, Codable {
    case github = "GitHub"
    case gitlab = "GitLab"
    case vercel = "Vercel"
    case netlify = "Netlify"
    case railway = "Railway"
    case sentry = "Sentry"
    case datadog = "Datadog"
    case uptime = "Uptime"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .gitlab: return "g.circle"
        case .vercel: return "triangle"
        case .netlify: return "n.square"
        case .railway: return "train.side.front.car"
        case .sentry: return "exclamationmark.triangle"
        case .datadog: return "d.square"
        case .uptime: return "antenna.radiowaves.left.and.right"
        case .custom: return "wrench.adjustable"
        }
    }

    var description: String {
        switch self {
        case .github: return "GitHub Actions, workflow status, commit checks"
        case .gitlab: return "GitLab CI/CD pipeline status"
        case .vercel: return "Vercel deployment status & previews"
        case .netlify: return "Netlify sites, deploys & build status"
        case .railway: return "Railway project deployments & status"
        case .sentry: return "Sentry error tracking & issue monitoring"
        case .datadog: return "Datadog monitors, metrics & alerts"
        case .uptime: return "HTTP endpoint availability & response time"
        case .custom: return "Custom checks: HTTP, ping, port, scripts"
        }
    }

    var configFields: [ConfigField] {
        switch self {
        case .github:
            return [
                .token(placeholder: "ghp_xxxxxxxxxxxx", label: "Personal Access Token"),
                .list(label: "Repository", placeholder: "user/repo", key: "repos")
            ]
        case .gitlab:
            return [
                .token(placeholder: "glpat-xxxxxxxx", label: "Personal Access Token"),
                .text(label: "GitLab URL", placeholder: "https://gitlab.com", key: "url"),
                .list(label: "Project", placeholder: "group/project", key: "repos")
            ]
        case .vercel:
            return [
                .token(placeholder: "xxxxxxxxxxxx", label: "Vercel Token"),
                .list(label: "Project ID", placeholder: "prj_xxxxxxxx", key: "projects")
            ]
        case .netlify:
            return [
                .token(placeholder: "nfp_xxxxxxxx", label: "Personal Access Token"),
                .list(label: "Site ID", placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", key: "sites")
            ]
        case .railway:
            return [
                .token(placeholder: "rly_xxxxxxxx", label: "Railway Token"),
                .list(label: "Project ID", placeholder: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", key: "projects")
            ]
        case .sentry:
            return [
                .token(placeholder: "sntrys_xxxxxxxx", label: "Auth Token"),
                .text(label: "Organization", placeholder: "org-slug", key: "org"),
                .text(label: "Project", placeholder: "project-slug", key: "project")
            ]
        case .datadog:
            return [
                .token(placeholder: "datadog-api-key", label: "API Key"),
                .token(placeholder: "datadog-app-key", label: "Application Key"),
                .text(label: "Site", placeholder: "datadoghq.com", key: "site")
            ]
        case .uptime:
            return [
                .list(label: "URL", placeholder: "https://example.com", key: "urls")
            ]
        case .custom:
            return [
                .list(label: "Check (type:target:expected)", placeholder: "http:https://example.com:200", key: "checks"),
                .text(label: "Name", placeholder: "My Check", key: "name"),
                .text(label: "Interval (seconds)", placeholder: "60", key: "interval"),
            ]
        }
    }
}

enum ConfigField {
    case token(placeholder: String, label: String)
    case text(label: String, placeholder: String, key: String)
    case list(label: String, placeholder: String, key: String)
}

struct ServiceAccount: Identifiable, Codable {
    var id = UUID()
    var name: String
    var serviceType: ServiceType
    var isEnabled: Bool = true

    var token: String = ""
    var extraToken: String = ""

    var textValues: [String: String] = [:]
    var listValues: [String: [String]] = [:]

    static func empty(_ type: ServiceType) -> ServiceAccount {
        ServiceAccount(
            name: type.rawValue,
            serviceType: type,
            token: "",
            extraToken: "",
            textValues: [:],
            listValues: [:]
        )
    }
}

enum TabType: String, CaseIterable {
    case dashboard = "Dashboard"
    case accounts = "Accounts"
    case processes = "Processes"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .accounts: return "link"
        case .processes: return "cpu"
        case .settings: return "gearshape"
        }
    }
}

extension StatusType {
    var color: Color {
        switch self {
        case .success: return Color(hex: 0x22C55E)
        case .warning: return Color(hex: 0xF59E0B)
        case .danger: return Color(hex: 0xEF4444)
        case .neutral: return Color(hex: 0x888888)
        }
    }
}
