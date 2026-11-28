import MapKit
import SwiftUI

struct FavoriteLocationsView: View {
    @Binding var data: Data
    let selection: SelectedCoordinate
    let choose: (SelectedCoordinate) -> Void
    @State private var query = ""
    private var places: [PinpointPlace] {
        (try? JSONDecoder().decode([PinpointPlace].self, from: data)) ?? []
    }
    private var filtered: [PinpointPlace] {
        query.isEmpty ? places : places.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    private func save(_ items: [PinpointPlace]) {
        if let encoded = try? JSONEncoder().encode(items) { data = encoded }
    }
    var body: some View {
        List {
            Section {
                NavigationLink {
                    FavoriteMapPicker(initial: selection) { coordinate, name in
                        save(places + [PinpointPlace(name: name, coordinate: coordinate)])
                    }
                } label: {
                    Label("Add a favorite", systemImage: "plus.circle.fill")
                        .font(.headline).foregroundStyle(Color.accentColor)
                }
            } footer: {
                Text("Choose any location using the interactive map.")
            }
            Section("Saved locations (\(places.count))") {
                if filtered.isEmpty {
                    ContentUnavailableView(query.isEmpty ? "No favorites yet" : "No matches", systemImage: "star", description: Text(query.isEmpty ? "Add your first location above." : "Try another name."))
                }
                ForEach(filtered) { place in
                    NavigationLink {
                        FavoriteDetailView(place: place, choose: choose, rename: { name in
                            save(places.map { item in
                                var updated = item
                                if item.id == place.id { updated.name = name }
                                return updated
                            })
                        }, remove: { save(places.filter { $0.id != place.id }) })
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill").foregroundStyle(Color.accentColor)
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name).font(.headline)
                                Text(favoriteCoordinates(place.coordinate)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Favorite Locations")
        .searchable(text: $query, prompt: "Find a favorite")
    }
}

private func favoriteCoordinates(_ coordinate: SelectedCoordinate) -> String {
    String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
}

private struct FavoriteMapPreview: View {
    let coordinate: SelectedCoordinate
    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: coordinate.coreLocationCoordinate, latitudinalMeters: 1200, longitudinalMeters: 1200)), interactionModes: []) {
            Marker("Location", coordinate: coordinate.coreLocationCoordinate).tint(Color.accentColor)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .allowsHitTesting(false)
    }
}

struct FavoriteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let coordinate: SelectedCoordinate
    let initialName: String
    let editing: Bool
    let save: (String) -> Void
    @State private var name = ""
    @State private var reviewing = false
    private var cleanName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var body: some View {
        Form {
            Section(reviewing ? "Step 2 of 2: Review" : "Step 1 of 2: Name your location") {
                FavoriteMapPreview(coordinate: coordinate)
                Text(favoriteCoordinates(coordinate)).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                if reviewing { LabeledContent("Name", value: cleanName) }
                else { TextField("e.g. Home, School, Vacation", text: $name).textInputAutocapitalization(.words) }
            }
            Section {
                if reviewing {
                    Button { save(cleanName); dismiss() } label: { Label(editing ? "Save changes" : "Save favorite", systemImage: "checkmark.circle.fill") }
                    Button("Back to name") { reviewing = false }
                } else {
                    Button("Continue") { reviewing = true }.disabled(cleanName.isEmpty)
                }
            }
        }
        .navigationTitle(editing ? "Rename favorite" : "New favorite")
        .onAppear { if name.isEmpty { name = initialName } }
    }
}

private struct FavoriteDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var place: PinpointPlace
    let choose: (SelectedCoordinate) -> Void
    let rename: (String) -> Void
    let remove: () -> Void
    @State private var confirmingRemoval = false
    var body: some View {
        Form {
            Section {
                FavoriteMapPreview(coordinate: place.coordinate)
                LabeledContent("Coordinates", value: favoriteCoordinates(place.coordinate))
            }
            Section {
                Button { choose(place.coordinate) } label: { Label("Set as selected location", systemImage: "mappin.and.ellipse").font(.headline) }
                NavigationLink {
                    FavoriteEditorView(coordinate: place.coordinate, initialName: place.name, editing: true) { name in
                        rename(name)
                        place.name = name
                    }
                } label: { Label("Rename favorite", systemImage: "pencil") }
                Button(role: .destructive) { confirmingRemoval = true } label: { Label("Remove favorite", systemImage: "trash") }
            } footer: {
                Text("Selecting this location moves your map pin. It does not change your GPS until you tap Set location.")
            }
        }
        .navigationTitle(place.name)
        .confirmationDialog("Remove this favorite?", isPresented: $confirmingRemoval, titleVisibility: .visible) {
            Button("Remove favorite", role: .destructive) { remove(); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
