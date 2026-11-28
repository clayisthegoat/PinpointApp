import SwiftUI
import Network

struct NetworkCheckView: View {
    @EnvironmentObject var model: AppModel
    @State private var result = "Not tested"
    @State private var running = false
    var body: some View {
        Form {
            Section("Internet check") {
                Text("Restore real GPS before testing. Compare results with your VPN on and off.")
                Text(result)
                Button("Test internet access") { Task { await test() } }
                    .disabled(running || model.simulatedCoordinate != nil)
                if model.simulatedCoordinate != nil { Text("Restore real location first.").foregroundStyle(.secondary) }
            }
            Section("About") {
                Text("This checks general HTTPS connectivity, not another app's location reporting. It does not alter VPN settings.")
            }
        }.navigationTitle("Network check")
    }
    @MainActor private func test() async {
        running = true
        defer { running = false }
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        let session = URLSession(configuration: config)
        defer { session.finishTasksAndInvalidate() }
        do {
            let (_, response) = try await session.data(from: URL(string: "https://example.com")!)
            if let http = response as? HTTPURLResponse {
                result = "HTTPS reachable (HTTP \(http.statusCode))"
            } else { result = "Received a response" }
        } catch { result = "Connection failed: \(error.localizedDescription)" }
    }
}
