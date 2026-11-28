import MapKit
import SwiftUI

struct FavoriteMapPicker: View {
    @Environment(\.dismiss) private var dismiss
    @State private var camera: MapCameraPosition
    @State private var region: MKCoordinateRegion
    @State private var query = ""
    @State private var searching = false
    @State private var errorMessage: String?
    @State private var confirmed: SelectedCoordinate?
    @State private var name = ""
    @State private var review = false
    @FocusState private var searchFocused: Bool
    let destinationOnly: Bool
    let save: (SelectedCoordinate, String) -> Void

    init(initial: SelectedCoordinate, destinationOnly: Bool = false, save: @escaping (SelectedCoordinate, String) -> Void) {
        let region = MKCoordinateRegion(center: initial.coreLocationCoordinate, latitudinalMeters: 1500, longitudinalMeters: 1500)
        _region = State(initialValue: region)
        _camera = State(initialValue: .region(region))
        self.destinationOnly = destinationOnly
        self.save = save
    }

    var body: some View {
        VStack(spacing: 12) {
            if let coordinate = confirmed {
                Form {
                    Section(review ? "Step 3 of 3: Review" : "Step 2 of 3: Name your favorite") {
                        Map(initialPosition: .region(MKCoordinateRegion(center: coordinate.coreLocationCoordinate, latitudinalMeters: 800, longitudinalMeters: 800)), interactionModes: []) {
                            Marker("Favorite", coordinate: coordinate.coreLocationCoordinate)
                        }.frame(height: 180).allowsHitTesting(false)
                        Text(String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)).font(.caption.monospacedDigit())
                        if review { LabeledContent("Name", value: name) }
                        else { TextField("Location name", text: $name).textInputAutocapitalization(.words) }
                    }
                    Section {
                        Button(review ? "Save favorite" : "Continue") {
                            if review {
                                save(coordinate, name.trimmingCharacters(in: .whitespacesAndNewlines))
                                dismiss()
                            } else { review = true }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        Button(review ? "Edit name" : "Adjust location") {
                            if review { review = false } else { confirmed = nil }
                        }
                    }
                }
            } else {
                Text(destinationOnly ? "Choose destination" : "Step 1 of 3 · Choose location").font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search address or place", text: $query)
                        .focused($searchFocused).submitLabel(.search).onSubmit { search() }
                    Button("Search") { search() }.disabled(searching || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }.padding(12).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14)).padding(.horizontal)
                ZStack(alignment: .bottomTrailing) {
                    Map(position: $camera, interactionModes: [.pan, .zoom]) {}
                        .mapStyle(.standard(elevation: .flat))
                        .onMapCameraChange(frequency: .continuous) { context in region = context.region }
                        .overlay {
                            VStack(spacing: 0) {
                                Image(systemName: "mappin").font(.system(size: 42, weight: .semibold)).foregroundStyle(Color.accentColor).shadow(radius: 3)
                                Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                            }.offset(y: -24).allowsHitTesting(false)
                        }
                    VStack(spacing: 0) {
                        Button { zoom(0.5) } label: { Image(systemName: "plus").frame(width: 48, height: 48) }.accessibilityLabel("Zoom in")
                        Divider().frame(width: 36)
                        Button { zoom(2) } label: { Image(systemName: "minus").frame(width: 48, height: 48) }.accessibilityLabel("Zoom out")
                    }.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)).padding()
                }.clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal)
                Text("Move the map under the pin. Pinch to zoom for precision.").font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Text(String(format: "%.6f, %.6f", region.center.latitude, region.center.longitude)).font(.caption.monospacedDigit())
                Button {
                    if destinationOnly { save(SelectedCoordinate(region.center), ""); dismiss() } else { confirmed = SelectedCoordinate(region.center) }
                    searchFocused = false
                } label: { Label("Confirm location", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(.borderedProminent).controlSize(.large).padding(.horizontal).disabled(searching || !SelectedCoordinate(region.center).isValid)
            }
        }
        .padding(.bottom, 12)
        .navigationTitle(destinationOnly ? "Destination" : "New favorite")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Search unavailable", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func zoom(_ factor: Double) {
        let span = MKCoordinateSpan(latitudeDelta: min(170, max(0.0001, region.span.latitudeDelta * factor)), longitudeDelta: min(350, max(0.0001, region.span.longitudeDelta * factor)))
        withAnimation { camera = .region(MKCoordinateRegion(center: region.center, span: span)) }
    }

    private func search() {
        guard !searching, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        searching = true
        searchFocused = false
        Task { @MainActor in
            defer { searching = false }
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.region = region
                let result = try await MKLocalSearch(request: request).start()
                guard let item = result.mapItems.first else { errorMessage = "No matching location found."; return }
                let target = MKCoordinateRegion(center: item.placemark.coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
                region = target
                withAnimation { camera = .region(target) }
            } catch { errorMessage = error.localizedDescription }
        }
    }
}
