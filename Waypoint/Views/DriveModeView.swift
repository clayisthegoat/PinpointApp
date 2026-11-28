import MapKit
import SwiftUI

struct DriveModeView: View {
    @EnvironmentObject var model: AppModel
    let initial: SelectedCoordinate
    let favorites: [PinpointPlace]
    var walking = false
    @State private var destination: SelectedCoordinate?
    @State private var previewOrigin: SelectedCoordinate?
    @State private var previewID = UUID()
    @State private var speed = 60.0
    @State private var variation = 0.0
    @State private var route: MKRoute?
    @State private var calculating = false
    @State private var starting = false
    @State private var error: String?

    var body: some View {
        Form {
            Section("Starting location") {
                if let origin = model.simulatedCoordinate { Text(String(format: "%.5f, %.5f", origin.latitude, origin.longitude)) }
                else { Text("Movement will start from your selected map pin.").font(.caption) }
            }
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
            }.disabled(calculating || starting || model.routeRunning)
            Section("Speed") {
                LabeledContent("Target speed", value: String(format: "%.0f mph · %.0f km/h", speed / 1.609344, speed))
                Slider(value: $speed, in: walking ? 1...10 : 10...120, step: 1)
                if !walking {
                LabeledContent("Test speed variation", value: String(format: "±%.0f mph · ±%.0f km/h", variation / 1.609344, variation))
                Slider(value: $variation, in: 0...20, step: 1)
                Text("Optional randomized speed changes for movement testing. Zero uses constant speed.").font(.caption)
                }
            }.disabled(model.routeRunning)
            Section("Route preview") {
                if let route {
                    Map(initialPosition: .rect(route.polyline.boundingMapRect)) {
                        MapPolyline(route.polyline).stroke(Color.accentColor, lineWidth: 5)
                    }.frame(height: 240).id(previewID)
                    LabeledContent("Distance", value: String(format: "%.1f mi · %.1f km", route.distance / 1609.344, route.distance / 1000))
                    LabeledContent("Estimated duration", value: String(format: "%.0f min", route.distance / (speed / 3.6) / 60))
                }
                Button(calculating ? "Calculating…" : "Preview route") { preview() }
                    .disabled(calculating || starting || destination == nil || model.routeRunning)
                if let error { Text(error).foregroundStyle(.red).font(.caption) }
            }
            Section {
                if model.routeRunning {
                    ProgressView(value: model.routeProgress)
                    Button(model.routePaused ? "Resume" : "Pause") { model.routePaused.toggle() }
                    Button("Stop movement", role: .destructive) { model.cancelRoute() }
                } else {
                    Button {
                        startMovement()
                    } label: { Label(starting ? "Starting route…" : (walking ? "Start walk" : "Start drive"), systemImage: walking ? "figure.walk" : "car.fill").frame(maxWidth: .infinity).contentShape(Rectangle()) }
                    .buttonStyle(.borderedProminent)
                    .sensoryFeedback(.selection, trigger: starting)
                    .disabled(destination == nil || calculating || starting)
                }
                
                Text("For location testing. Keep the app active for reliable updates.").font(.caption)
            }
        }.navigationTitle(walking ? "Walk Mode" : "Drive Mode")
        .onAppear { if walking && speed > 10 { speed = 5 } }
        .onChange(of: model.simulatedCoordinate) { _, _ in if !model.routeRunning && !starting { route = nil } }
    }

    private func startMovement() {
        guard let destination, !starting else { return }
        starting = true
        error = nil
        Task { @MainActor in
            defer { starting = false }
            guard !model.isChangingSimulation, !model.areLocationWritesPausedForCellularHandoff else {
                error = "Location updates are busy or paused. Try again when ready."
                return
            }
            if model.simulatedCoordinate == nil { await model.startSimulation(at: initial) }
            guard let origin = model.simulatedCoordinate else {
                error = "Could not establish the starting location. Check connection diagnostics."
                return
            }
            model.beginRoute(to: destination, walking: walking, speed: speed, testVariation: walking ? 0 : variation, previewedRoute: previewOrigin == origin ? route : nil)
            if !model.routeRunning { error = "Movement could not start. Check connection diagnostics." }
        }
    }

    private func preview() {
        guard let destination else { return }
        let origin = model.simulatedCoordinate ?? initial
        calculating = true
        error = nil
        route = nil
        Task { @MainActor in
            defer { calculating = false }
            do {
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coreLocationCoordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coreLocationCoordinate))
                request.transportType = walking ? .walking : .automobile
                route = try await MKDirections(request: request).calculate().routes.first
                previewOrigin = origin
                previewID = UUID()
                if route == nil { error = "No mapped route found. Try a reachable destination." }
            } catch { self.error = error.localizedDescription }
        }
    }
}
