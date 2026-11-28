import SwiftUI

@main
struct WaypointApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("pinpointTheme") private var theme = "System"
    @AppStorage("pinpointAccent") private var accent = "Blue"
    private var tint: Color { PinpointAppearance.color(accent) }
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(tint)
                .accentColor(tint)
                .preferredColorScheme(theme == "Dark" ? .dark : theme == "Light" ? .light : nil)
                .environmentObject(model)
                .onOpenURL { model.handleIncomingURL($0) }
                .task { model.refreshLocalState() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        model.applicationBecameActive()
                    } else {
                        model.applicationBecameInactive()
                    }
                }
        }
    }
}
