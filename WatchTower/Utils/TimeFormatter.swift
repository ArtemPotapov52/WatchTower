import Foundation

enum TimeFormatter {
    static func relative(to date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        switch interval {
        case ..<10: return "только что"
        case ..<60: return "\(Int(interval))с назад"
        case ..<3600: return "\(Int(interval / 60))м назад"
        case ..<86400: return "\(Int(interval / 3600))ч назад"
        default: return "\(Int(interval / 86400))д назад"
        }
    }
}
