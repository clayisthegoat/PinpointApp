import SwiftUI
import CoreLocation

final class LocationDiagnosticReader: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var status = "Not started"
    @Published var latest: CLLocation?
    @Published var count = 0
    @Published var interval: TimeInterval?
    override init() {
        super.init()
        manager.delegate = self
    }
    func start() {
        latest = nil
        count = 0
        interval = nil
        status = "Waiting for location"
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    func stop() { manager.stopUpdatingLocation(); status = "Stopped" }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        if let previous = latest { interval = location.timestamp.timeIntervalSince(previous.timestamp) }
        latest = location
        count += locations.count
        status = "Receiving updates"
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
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
                Button("Start reading") { reader.start() }
                Button("Stop reading") { reader.stop() }
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
            Section("Privacy") { Text("Read-only diagnostic data stays on this screen. Other apps may handle location data differently.") }
        }.navigationTitle("Location diagnostics").onDisappear { reader.stop() }
    }
}
