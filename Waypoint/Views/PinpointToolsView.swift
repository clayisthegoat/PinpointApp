import MapKit
import SwiftUI

struct PinpointPlace: Codable, Identifiable {
    var id = UUID()
    var name: String
    var coordinate: SelectedCoordinate
}

extension MapSpoofView {
    var pinpointMapStyle: MapStyle {
        switch mapStyleChoice {
        case "Satellite": return .imagery(elevation: .realistic)
        case "Hybrid": return .hybrid(elevation: .realistic)
        default: return .standard(elevation: .realistic)
        }
    }
    func recordHistory(_ coordinate: SelectedCoordinate) {
        var items = (try? JSONDecoder().decode([PinpointPlace].self, from: historyData)) ?? []
        items.removeAll { $0.coordinate == coordinate }
        items.insert(PinpointPlace(name: String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude), coordinate: coordinate), at: 0)
        historyData = (try? JSONEncoder().encode(Array(items.prefix(50)))) ?? Data()
    }
    var pinpointTools: some View {
        PinpointToolsView(favoritesData: $namedFavoritesData, legacyData: $favoritesData, historyData: $historyData, mapStyleChoice: $mapStyleChoice, selection: selection) { coordinate in
            select(coordinate.coreLocationCoordinate)
            cameraPosition = .region(MKCoordinateRegion(center: coordinate.coreLocationCoordinate, latitudinalMeters: 2000, longitudinalMeters: 2000))
            toolsPresented = false
        }
        .environmentObject(model)
    }
}

struct PinpointToolsView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) var dismiss
    @Binding var favoritesData: Data
    @Binding var legacyData: Data
    @Binding var historyData: Data
    @Binding var mapStyleChoice: String
    let selection: SelectedCoordinate
    let choose: (SelectedCoordinate) -> Void
    @State private var minutes = 15
    private var favorites: [PinpointPlace] {
        (try? JSONDecoder().decode([PinpointPlace].self, from: favoritesData)) ?? []
    }
    private var history: [PinpointPlace] {
        (try? JSONDecoder().decode([PinpointPlace].self, from: historyData)) ?? []
    }
    private func save(_ items: [PinpointPlace]) {
        favoritesData = (try? JSONEncoder().encode(items)) ?? Data()
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("Connection dashboard") {
                    status("Pairing record", model.pairingState.isReady)
                    status("Developer tunnel", model.tunnelState.isReady)
                    status("Developer image", model.developerImageState.isReady)
                    status("LocalDevVPN installed", model.isLocalDevVPNInstalled)
                    status("Simulation active", model.simulatedCoordinate != nil)
                    status("Background keepalive", model.backgroundKeepAliveEnabled)
                }
                Section("Map appearance") {
                    Picker("Style", selection: $mapStyleChoice) {
                        ForEach(["Standard", "Satellite", "Hybrid"], id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Saved places") {
                    NavigationLink {
                        FavoriteLocationsView(data: $favoritesData, selection: selection, choose: choose)
                    } label: {
                        Label("Favorite Locations", systemImage: "star.fill")
                            .foregroundStyle(.blue)
                    }
                }
                Section("Location history") {
                    ForEach(history) { place in Button(place.name) { choose(place.coordinate) } }
                    Button("Clear history", role: .destructive) { historyData = Data() }
                }
                Section("Route simulation") {
                    NavigationLink { DriveModeView(initial: selection, favorites: favorites) } label: { Label("Drive Mode", systemImage: "car.fill").foregroundStyle(.blue) }
                    NavigationLink { DriveModeView(initial: selection, favorites: favorites, walking: true) } label: { Label("Walk Mode", systemImage: "figure.walk").foregroundStyle(.blue) }
                    Text("Choose a destination and preview a mapped route.").font(.caption)
                    if model.routeRunning {
                        ProgressView(value: model.routeProgress)
                        Button("Stop movement", role: .destructive) { model.cancelRoute() }
                    }
                }
                Section("Automatic restore") {
                    Picker("Restore after", selection: $minutes) {
                        ForEach([5,15,30,60,120], id: \.self) { Text("\($0) minutes").tag($0) }
                    }
                    if let deadline = model.restoreDeadline {
                        Text(deadline, style: .timer).monospacedDigit()
                        Button("Cancel timer") { model.cancelRestoreTimer() }
                    } else {
                        Button("Start restore timer") { model.scheduleRestore(minutes: minutes) }
                            .disabled(model.simulatedCoordinate == nil)
                    }
                    Text("Requires the app to remain running; iOS suspension may delay restoration.").font(.caption)
                }
            }
            .navigationTitle("Pinpoint tools")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear {
                if let old = try? JSONDecoder().decode([SelectedCoordinate].self, from: legacyData), !old.isEmpty {
                    save(favorites + old.map { PinpointPlace(name: String(format: "%.5f, %.5f", $0.latitude, $0.longitude), coordinate: $0) })
                    legacyData = Data()
                }
            }
        }
    }
    private func status(_ title: String, _ ready: Bool) -> some View {
        Label(title, systemImage: ready ? "checkmark.circle.fill" : "circle.dashed")
            .foregroundStyle(ready ? Color.green : Color.secondary)
    }
}
