import SwiftUI

struct SyntheticEventTestView: View {
    @State private var seconds = 2
    @State private var running = false
    @State private var count = 0
    @State private var first: Date?
    @State private var last: Date?
    @State private var interval: TimeInterval?
    var body: some View {
        Form {
            Section("Local test only") {
                Text("Generates mock events in this screen. Does not write GPS coordinates, use the developer tunnel, or deliver events to other apps.")
                Picker("Test interval", selection: $seconds) {
                    ForEach([1, 2, 5, 10], id: \.self) { Text("\($0) seconds").tag($0) }
                }.disabled(running)
                Button(running ? "Stop test" : "Start test") {
                    if running { running = false }
                    else { count = 0; first = nil; last = nil; interval = nil; running = true }
                }
            }
            Section("Mock event statistics") {
                LabeledContent("Events", value: String(count))
                if let interval { LabeledContent("Last interval", value: String(format: "%.2f s", interval)) }
                if let first, let last, count > 1 {
                    LabeledContent("Average interval", value: String(format: "%.2f s", last.timeIntervalSince(first) / Double(count - 1)))
                }
            }
        }
        .navigationTitle("Synthetic event test")
        .task(id: running) {
            guard running else { return }
            while !Task.isCancelled {
                let now = Date()
                if let last { interval = now.timeIntervalSince(last) }
                if first == nil { first = now }
                last = now
                count += 1
                do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            }
        }
        .onDisappear { running = false }
    }
}
