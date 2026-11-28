import SwiftUI
import CoreLocation

final class LocationDiagnosticReader: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var status = "Not started"
    @Published var latest: CLLocation?
    @Published var count = 0
    @Published var interval: TimeInterval?
    @Published var started: Date?
    @Published var stopped: Date?
    @Published var lastReceived: Date?
    @Published var errorCount = 0
    @Published var running = false
    override init() {
        super.init()
        manager.delegate = self
    }
    func start() {
        started = Date()
        stopped = nil
        lastReceived = nil
        errorCount = 0
        running = true
        latest = nil
        count = 0
        interval = nil
        status = "Waiting for location"
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    func stop() { manager.stopUpdatingLocation(); if running { stopped = Date() }; running = false; status = "Stopped" }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard running, let location = locations.last else { return }
        lastReceived = Date()
        if let previous = latest { interval = location.timestamp.timeIntervalSince(previous.timestamp) }
        latest = location
        count += locations.count
        status = "Receiving updates"
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorCount += 1
        status = error.localizedDescription
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted { status = "Location access unavailable" }
    }
}

struct LocationDiagnosticsView: View {
    @StateObject private var reader = LocationDiagnosticReader()
    var body: some View {
        Form {
            Section("Core Location") {
                Text(reader.status)
                Button("Start reading") { reader.start() }.disabled(reader.running)
                Button("Stop reading") { reader.stop() }.disabled(!reader.running)
                LabeledContent("Updates", value: String(reader.count))
                if let interval = reader.interval { LabeledContent("Last update interval", value: String(format: "%.1f s", interval)) }
                if let location = reader.latest {
                    LabeledContent("Latitude", value: String(format: "%.5f", location.coordinate.latitude))
                    LabeledContent("Longitude", value: String(format: "%.5f", location.coordinate.longitude))
                    LabeledContent("Accuracy", value: location.horizontalAccuracy >= 0 ? String(format: "%.1f m", location.horizontalAccuracy) : "Unavailable")
                    LabeledContent("Source", value: location.sourceInformation.map { $0.isSimulatedBySoftware ? "Software simulated" : "Not marked simulated" } ?? "Unknown")
                    LabeledContent("Timestamp") { Text(location.timestamp, style: .time) }
                }
            }
            Section("Observation summary · Beta") {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let elapsed = max(0, (reader.stopped ?? context.date).timeIntervalSince(reader.started ?? context.date))
                    VStack(alignment: .leading, spacing: 10) {
                        LabeledContent("Observation duration", value: String(format: "%.0f s", elapsed))
                        LabeledContent("Callback errors", value: String(reader.errorCount))
                        if let received = reader.lastReceived {
                            LabeledContent("Last callback age", value: String(format: "%.0f s", max(0, context.date.timeIntervalSince(received))))
                        }
                        Text("A quiet location stream is not proof of a disconnected session.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                ShareLink(item: "Pinpoint location observation: \(reader.count) readings; \(reader.errorCount) callback errors. Coordinates excluded.") { Label("Share summary", systemImage: "square.and.arrow.up") }
            }
            Section("Privacy") { Text("Read-only observations. Shared summaries exclude coordinates and pairing credentials.") }
        }.navigationTitle("Location diagnostics").onDisappear { reader.stop() }
    }
}
