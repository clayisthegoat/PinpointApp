import SwiftUI
import ActivityKit

struct DiagnosticsActivityView: View {
    @State private var message = ""
    var body: some View {
        Section("Live Activity") {
            Button("Start diagnostic timer") {
                Task {
                    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                        message = "Live Activities are disabled or unavailable."
                        return
                    }
                    for activity in Activity<PinpointActivityAttributes>.activities {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    }
                    do {
                        _ = try Activity.request(attributes: PinpointActivityAttributes(started: .now),
                            content: ActivityContent(state: .init(status: "Diagnostic timer"), staleDate: nil),
                            pushType: nil)
                        message = "Timer started."
                    } catch { message = error.localizedDescription }
                }
            }
            Button("End diagnostic timer") {
                Task {
                    for activity in Activity<PinpointActivityAttributes>.activities {
                        await activity.end(nil, dismissalPolicy: .immediate)
                    }
                    message = "Timer ended."
                }
            }
            if !message.isEmpty { Text(message).font(.caption) }
            Text("Displays elapsed diagnostic time, not GPS or connection status.").font(.caption).foregroundStyle(.secondary)
        }
    }
}
