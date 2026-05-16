import SwiftUI

@main
struct WatchTowerApp: App {
    @State private var appState = AppState()

    private var colorScheme: ColorScheme? {
        switch appState.colorSchemePreference {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            MainTabView()
                .environment(appState)
                .preferredColorScheme(colorScheme)
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra("WatchTower", systemImage: "eye") {
            PopupView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
