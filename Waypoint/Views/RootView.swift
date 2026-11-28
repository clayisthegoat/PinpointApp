import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("pinpointAccent") private var accent = "Blue"

    var body: some View {
        NavigationStack {
            MapSpoofView()
        }
        .sheet(isPresented: $model.isSetupPresented) {
            NavigationStack {
                SetupView()
            }
            .tint(PinpointAppearance.color(accent))
            .accentColor(PinpointAppearance.color(accent))
        }
        .alert(item: $model.alert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

