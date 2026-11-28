import SwiftUI

struct FavoriteFoldersView: View {
    @Binding var data: Data
    @State private var folder = ""
    @State private var selectedID: UUID?
    private var places: [PinpointPlace] { (try? JSONDecoder().decode([PinpointPlace].self, from: data)) ?? [] }
    private var folders: [String] { Array(Set(places.map { $0.folder ?? "Unfiled" })).sorted() }
    var body: some View {
        Form {
            Section("Assign folder") {
                Picker("Favorite", selection: $selectedID) {
                    Text("Select a place").tag(nil as UUID?)
                    ForEach(places) { Text($0.name).tag(Optional($0.id)) }
                }
                TextField("Folder name", text: $folder)
                Button("Assign") {
                    var items = places
                    guard let index = items.firstIndex(where: { $0.id == selectedID }) else { return }
                    let name = folder.trimmingCharacters(in: .whitespacesAndNewlines)
                    items[index].folder = name.isEmpty ? nil : name
                    if let encoded = try? JSONEncoder().encode(items) { data = encoded }
                }.disabled(selectedID == nil)
            }
            ForEach(folders, id: \.self) { name in
                Section(name) {
                    ForEach(places.filter { ($0.folder ?? "Unfiled") == name }) { place in
                        Label(place.name, systemImage: "star")
                    }
                }
            }
        }.navigationTitle("Favorite folders")
    }
}

struct PinpointHealthView: View {
    @EnvironmentObject var model: AppModel
    @AppStorage("pinpointHistory") private var history = Data()
    @AppStorage("pinpointNamedFavorites") private var favorites = Data()
    var body: some View {
        Form {
            Section("Connection health") {
                LabeledContent("Pairing", value: model.pairingState.isReady ? "Ready" : "Not ready")
                LabeledContent("Tunnel", value: model.tunnelState.isReady ? "Ready" : "Not ready")
                LabeledContent("Developer image", value: model.developerImageState.isReady ? "Ready" : "Not ready")
                NavigationLink("Detailed diagnostics") { PinpointDiagnosticsView() }
            }
            Section("Local analytics") {
                LabeledContent("Saved favorites", value: String(((try? JSONDecoder().decode([PinpointPlace].self, from: favorites)) ?? []).count))
                LabeledContent("History entries", value: String(((try? JSONDecoder().decode([PinpointPlace].self, from: history)) ?? []).count))
                Text("Counts reflect locally stored entries, not total sessions.").font(.caption)
            }
            Section("Current notices") {
                if !model.preparationMessage.isEmpty { Text(model.preparationMessage) }
                if !model.tunnelState.isReady { Label("Developer tunnel not ready", systemImage: "exclamationmark.triangle") }
                if !model.isLocalDevVPNInstalled { Label("LocalDevVPN not installed", systemImage: "exclamationmark.triangle") }
                Text("Current app notices only; not a persistent notification history.").font(.caption)
            }
        }.navigationTitle("Health & notices")
    }
}
