import SwiftUI

enum Typography {
    static let caption = Font.system(size: 11, weight: .regular)
    static let captionMedium = Font.system(size: 11, weight: .medium)
    static let small = Font.system(size: 12, weight: .regular)
    static let smallMedium = Font.system(size: 12, weight: .medium)
    static let body = Font.system(size: 13, weight: .regular)
    static let bodyMedium = Font.system(size: 13, weight: .medium)
    static let subtitle = Font.system(size: 15, weight: .regular)
    static let subtitleMedium = Font.system(size: 15, weight: .medium)
}

extension View {
    func titleStyle() -> some View {
        self.font(.system(size: 12, weight: .medium))
            .tracking(-0.2)
    }

    func sectionHeaderStyle() -> some View {
        self.font(.system(size: 11, weight: .regular))
            .tracking(-0.2)
    }

    func statusTextStyle() -> some View {
        self.font(.system(size: 11, weight: .regular))
    }

    func bodyStyle() -> some View {
        self.font(.system(size: 13, weight: .regular))
    }
}
