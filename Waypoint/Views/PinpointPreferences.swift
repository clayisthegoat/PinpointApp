import SwiftUI
import UniformTypeIdentifiers

struct PinpointPreferences: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("pinpointTheme") private var theme = "System"
    @AppStorage("pinpointAccent") private var accent = "Blue"
    @AppStorage("pinpointHaptics") private var haptics = true
    @AppStorage("pinpointMapStyle") private var mapStyle = "Standard"
    @AppStorage("pinpointShowFavorites") private var showFavorites = true
    @AppStorage("pinpointLiveActivity") private var liveActivity = true
    @State private var updateStatus = ""
    @State private var checking = false
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $theme) {
                    ForEach(["System", "Light", "Dark"], id: \.self) { Text($0) }
                }
                Picker("Accent", selection: $accent) {
                    ForEach(["Blue", "Purple", "Green", "Orange"], id: \.self) { Text($0) }
                }
            }
            Section("Map & interaction") {
                Toggle("Interface haptics", isOn: $haptics)
                Toggle("Show favorites on map", isOn: $showFavorites)
                NavigationLink("Bottom shortcuts") { PinpointShortcutEditor() }
                Toggle("Spoofing Live Activity", isOn: $liveActivity)
                    .onChange(of: liveActivity) { _, _ in model.refreshSimulationActivity() }
                Picker("Map style", selection: $mapStyle) {
                    ForEach(["Standard", "Satellite", "Hybrid"], id: \.self) { Text($0) }
                }
            }
            Section("Data") {
                NavigationLink { PinpointBackupView() } label: { Label("Backup & restore", systemImage: "externaldrive") }
            }
            Section("Updates") {
                NavigationLink("What’s new") { PinpointChangelogView() }
                LabeledContent("Installed", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")
                Button { Task { await checkUpdates() } } label: {
                    HStack {
                        Label("Check for updates", systemImage: "arrow.down.circle")
                        Spacer()
                        if checking { ProgressView() }
                    }
                }.disabled(checking)
                if !updateStatus.isEmpty { Text(updateStatus).font(.caption) }
                Link("GitHub releases", destination: URL(string: "https://github.com/clayisthegoat/PinpointApp/releases")!)
            }
            Section("About") {
                LabeledContent("App", value: "Pinpoint")
                Link("Source code & license", destination: URL(string: "https://github.com/clayisthegoat/PinpointApp")!)
            }
        }.navigationTitle("Preferences")
    }
    private func checkUpdates() async {
        checking = true
        defer { checking = false }
        do {
            let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.github.com/repos/clayisthegoat/PinpointApp/releases/latest")!)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { updateStatus = "GitHub request failed."; return }
            let release = try JSONDecoder().decode(Release.self, from: data)
            let latest = String(release.tag_name.dropFirst()).components(separatedBy: "-").first ?? ""
            let installed = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
            updateStatus = latest.compare(installed, options: .numeric) == .orderedDescending ? "Update available: " + latest : "No newer version found (" + latest + ")."
        } catch { updateStatus = error.localizedDescription }
    }
    private struct Release: Decodable { let tag_name: String }
}

struct PinpointBackup: Codable {
    var schema = 1
    var favorites: [PinpointPlace]
    var theme: String
    var accent: String
    var mapStyle: String
    var haptics: Bool
}
struct PinpointBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
struct PinpointBackupView: View {
    @AppStorage("pinpointNamedFavorites") private var favorites = Data()
    @AppStorage("pinpointTheme") private var theme = "System"
    @AppStorage("pinpointAccent") private var accent = "Blue"
    @AppStorage("pinpointMapStyle") private var mapStyle = "Standard"
    @AppStorage("pinpointHaptics") private var haptics = true
    @State private var document = PinpointBackupDocument()
    @State private var exporting = false
    @State private var importing = false
    @State private var pending: PinpointBackup?
    @State private var confirm = false
    @State private var status = ""
    var body: some View {
        Form {
            Text("Backups contain saved places and preferences, not pairing credentials. Saved coordinates may be private.")
            Button("Export backup") {
                do {
                    let places = favorites.isEmpty ? [] : try JSONDecoder().decode([PinpointPlace].self, from: favorites)
                    document = PinpointBackupDocument(data: try JSONEncoder().encode(PinpointBackup(favorites: places, theme: theme, accent: accent, mapStyle: mapStyle, haptics: haptics)))
                    exporting = true
                } catch { status = error.localizedDescription }
            }
            Button("Import backup") { importing = true }
            Text(status).font(.caption)
        }.navigationTitle("Backup")
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "Pinpoint-backup") { result in
            switch result { case .success: status = "Backup exported."; case .failure(let error): status = error.localizedDescription }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let backup = try JSONDecoder().decode(PinpointBackup.self, from: Data(contentsOf: url))
                guard backup.schema == 1, backup.favorites.allSatisfy({ $0.coordinate.isValid }) else { throw CocoaError(.fileReadCorruptFile) }
                pending = backup
                confirm = true
            } catch { status = error.localizedDescription }
        }
        .confirmationDialog("Replace saved places and preferences?", isPresented: $confirm) {
            Button("Replace", role: .destructive) {
                guard let b = pending, let data = try? JSONEncoder().encode(b.favorites) else { return }
                favorites = data; theme = b.theme; accent = b.accent; mapStyle = b.mapStyle; haptics = b.haptics
                pending = nil; status = "Backup restored."
            }
            Button("Cancel", role: .cancel) { pending = nil }
        }
    }
}
