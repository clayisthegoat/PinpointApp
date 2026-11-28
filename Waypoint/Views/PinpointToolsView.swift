import MapKit
import SwiftUI

struct PinpointPlace: Codable, Identifiable {
    var id = UUID()
    var name: String
    var coordinate: SelectedCoordinate
    var folder: String? = nil
    var recordedAt: Date? = nil
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
        items.insert(PinpointPlace(name: String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude), coordinate: coordinate, recordedAt: .now), at: 0)
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
                Section("Connection & diagnostics") {
                    NavigationLink { PinpointDiagnosticsView().environmentObject(model) } label: { Label("Connection diagnostics", systemImage: "stethoscope") }
                    status("Pairing record", model.pairingState.isReady)
                    status("Developer tunnel", model.tunnelState.isReady)
                    status("Developer image", model.developerImageState.isReady)
                    status("LocalDevVPN installed", model.isLocalDevVPNInstalled)
                    status("Simulation active", model.simulatedCoordinate != nil)
                    status("Background keepalive", model.backgroundKeepAliveEnabled)
                }
                Section("Preferences & data") {
                    NavigationLink { PinpointPreferences() } label: { Label("Appearance, backup & updates", systemImage: "gearshape") }
                    NavigationLink { PinpointHealthView() } label: { Label("Health, analytics & notices", systemImage: "heart.text.square") }
                    NavigationLink { FavoriteFoldersView(data: $favoritesData) } label: { Label("Favorite folders", systemImage: "folder") }
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
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Section("Location history") {
                    NavigationLink {
                        PinpointHistoryView(data: $historyData, choose: choose)
                    } label: {
                        Label("Recent locations", systemImage: "clock.arrow.circlepath")
                        Spacer()
                        Text("\(history.count)").foregroundStyle(.secondary)
                    }
                }
                Section("Route simulation") {
                    NavigationLink { DriveModeView(initial: selection, favorites: favorites) } label: { Label("Drive Mode", systemImage: "car.fill").foregroundStyle(Color.accentColor) }
                    NavigationLink { DriveModeView(initial: selection, favorites: favorites, walking: true) } label: { Label("Walk Mode", systemImage: "figure.walk").foregroundStyle(Color.accentColor) }
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
            .navigationTitle("Settings")
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

struct PinpointHistoryView: View {
    @Binding var data: Data
    let choose: (SelectedCoordinate) -> Void
    @State private var query = ""
    @State private var confirmClear = false
    private var items: [PinpointPlace] {
        (try? JSONDecoder().decode([PinpointPlace].self, from: data)) ?? []
    }
    private var visible: [PinpointPlace] {
        query.isEmpty ? items : items.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    private func remove(_ ids: Set<UUID>) {
        if let encoded = try? JSONEncoder().encode(items.filter { !ids.contains($0.id) }) {
            data = encoded
        }
    }
    var body: some View {
        List {
            if visible.isEmpty {
                ContentUnavailableView(query.isEmpty ? "No recent locations" : "No matching locations",
                    systemImage: "clock", description: Text(query.isEmpty ? "Locations appear here after you set a simulated location." : "Try another search."))
            }
            ForEach(visible) { place in
                Button { choose(place.coordinate) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.name).foregroundStyle(.primary)
                        if let date = place.recordedAt {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { offsets in remove(Set(offsets.map { visible[$0].id })) }
        }
        .navigationTitle("Location history")
        .searchable(text: $query, prompt: "Search locations")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Clear", role: .destructive) { confirmClear = true }.disabled(items.isEmpty)
            }
        }
        .confirmationDialog("Clear all location history?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear history", role: .destructive) { data = Data() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Saved favorites will not be affected.") }
    }
}
