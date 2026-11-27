import MapKit
import SwiftUI

struct DriveModeView: View {
    @EnvironmentObject var model: AppModel
    let initial: SelectedCoordinate
    let favorites: [PinpointPlace]
    @State private var destination: SelectedCoordinate?
    @State private var speed = 60.0
    @State private var variation = 0.0
    @State private var route: MKRoute?
    @State private var calculating = false
    @State private var error: String?

    var body: some View {
        Form {
            Section("Destination") {
                NavigationLink {
                    FavoriteMapPicker(initial: destination ?? initial, destinationOnly: true) { coordinate, _ in
                        destination = coordinate
                        route = nil
                    }
                } label: { Label("Choose on map", systemImage: "map") }
                ForEach(favorites) { place in
                    Button { destination = place.coordinate; route = nil } label: {
                        Label(place.name, systemImage: "star")
                    }
                }
                if let destination {
                    Text(String(format: "%.5f, %.5f", destination.latitude, destination.longitude)).font(.caption.monospacedDigit())
                }
            }.disabled(calculating || model.routeRunning)
            Section("Speed") {
                LabeledContent("Target speed", value: String(format: "%.0f mph · %.0f km/h", speed / 1.609344, speed))
                Slider(value: $speed, in: 10...120, step: 1)
                LabeledContent("Test speed variation", value: String(format: "±%.0f mph · ±%.0f km/h", variation / 1.609344, variation))
                Slider(value: $variation, in: 0...20, step: 1)
                Text("Optional randomized speed changes for movement testing. Zero uses constant speed.").font(.caption)
            }.disabled(model.routeRunning)
            Section("Route preview") {
                if let route {
                    Map(initialPosition: .rect(route.polyline.boundingMapRect)) {
                        MapPolyline(route.polyline).stroke(.blue, lineWidth: 5)
                    }.frame(height: 200)
                    LabeledContent("Distance", value: String(format: "%.1f mi · %.1f km", route.distance / 1609.344, route.distance / 1000))
                    LabeledContent("Estimated duration", value: String(format: "%.0f min", route.distance / (speed / 3.6) / 60))
                }
                Button(calculating ? "Calculating…" : "Preview route") { preview() }
                    .disabled(calculating || destination == nil || model.simulatedCoordinate == nil || model.routeRunning)
                if let error { Text(error).foregroundStyle(.red).font(.caption) }
            }
            Section {
                if model.routeRunning {
                    ProgressView(value: model.routeProgress)
                    Button(model.routePaused ? "Resume drive" : "Pause drive") { model.routePaused.toggle() }
                    Button("Stop drive", role: .destructive) { model.cancelRoute() }
                } else {
                    Button {
                        if let destination { model.beginRoute(to: destination, walking: false, speed: speed, testVariation: variation) }
                    } label: { Label("Start drive", systemImage: "car.fill") }
                    .disabled(destination == nil || route == nil || calculating || model.simulatedCoordinate == nil || model.isChangingSimulation || model.areLocationWritesPausedForCellularHandoff)
                }
                if model.simulatedCoordinate == nil { Text("Set a simulated starting location first.").font(.caption) }
                Text("For location testing. Keep the app active for reliable updates.").font(.caption)
            }
        }.navigationTitle("Drive Mode")
    }

    private func preview() {
        guard let origin = model.simulatedCoordinate, let destination else { return }
        calculating = true
        error = nil
        route = nil
        Task { @MainActor in
            defer { calculating = false }
            do {
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coreLocationCoordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coreLocationCoordinate))
                request.transportType = .automobile
                route = try await MKDirections(request: request).calculate().routes.first
                if route == nil { error = "No driving route found." }
            } catch { self.error = error.localizedDescription }
        }
    }
}
