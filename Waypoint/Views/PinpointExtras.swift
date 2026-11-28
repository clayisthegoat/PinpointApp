import SwiftUI

struct PinpointShortcut: Identifiable {
    let id: String
    let title: String
    let symbol: String
    static let all = [
        Self(id: "favorites", title: "Favorites", symbol: "star.fill"),
        Self(id: "walk", title: "Walk", symbol: "figure.walk"),
        Self(id: "drive", title: "Drive", symbol: "car.fill"),
        Self(id: "diagnostics", title: "Check", symbol: "stethoscope"),
        Self(id: "history", title: "History", symbol: "clock"),
        Self(id: "changelog", title: "What's new", symbol: "doc.text"),
        Self(id: "settings", title: "Preferences", symbol: "gearshape")
    ]
}

struct PinpointShortcutEditor: View {
    @AppStorage("pinpointShortcuts") private var order = "favorites,walk,drive,diagnostics"
    private var ids: [String] { order.split(separator: ",").map(String.init) }
    var body: some View {
        List {
            Section("Selected (up to four)") {
                ForEach(ids, id: \.self) { id in
                    if let item = PinpointShortcut.all.first(where: { $0.id == id }) {
                        Label(item.title, systemImage: item.symbol)
                    }
                }.onMove { from, to in
                    var next = ids
                    next.move(fromOffsets: from, toOffset: to)
                    order = next.joined(separator: ",")
                }.onDelete { offsets in
                    var next = ids
                    next.remove(atOffsets: offsets)
                    order = next.joined(separator: ",")
                }
            }
            Section("Available") {
                ForEach(PinpointShortcut.all.filter { !ids.contains($0.id) }) { item in
                    Button { order = (ids + [item.id]).joined(separator: ",") } label: {
                        Label(item.title, systemImage: item.symbol)
                    }.disabled(ids.count >= 4)
                }
            }
            Button("Reset defaults") { order = "favorites,walk,drive,diagnostics" }
        }.navigationTitle("Bottom shortcuts").toolbar { EditButton() }
    }
}

struct PinpointChangelogView: View {
    var body: some View {
        ScrollView {
            Text(Bundle.main.url(forResource: "CHANGELOG", withExtension: "md").flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "Release notes unavailable.")
                .frame(maxWidth: .infinity, alignment: .leading).padding()
        }.navigationTitle("What's new")
    }
}

struct PinpointLogEntry: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    let event: String
    let severity: String
}

@MainActor
final class PinpointLog: ObservableObject {
    static let shared = PinpointLog()
    @Published private(set) var entries: [PinpointLogEntry] = []
    private let key = "pinpointDiagnosticLog"
    private init() {
        if let data = UserDefaults.standard.data(forKey: key) {
            entries = (try? JSONDecoder().decode([PinpointLogEntry].self, from: data)) ?? []
        }
    }
    func add(_ event: String, severity: String = "Info") {
        entries.insert(.init(event: event, severity: severity), at: 0)
        entries = Array(entries.prefix(200))
        save()
    }
    func clear() { entries = []; save() }
    private func save() { UserDefaults.standard.set(try? JSONEncoder().encode(entries), forKey: key) }
}

struct PinpointLogView: View {
    @ObservedObject private var log = PinpointLog.shared
    @State private var filter = "All"
    @State private var confirm = false
    private var visible: [PinpointLogEntry] { log.entries.filter { filter == "All" || $0.severity == filter } }
    var body: some View {
        List {
            Picker("Severity", selection: $filter) {
                ForEach(["All", "Info", "Error"], id: \.self) { Text($0) }
            }
            if visible.isEmpty { ContentUnavailableView("No events", systemImage: "list.bullet") }
            ForEach(visible) { entry in
                VStack(alignment: .leading) {
                    Text(entry.event)
                    Text(entry.date.formatted() + " · " + entry.severity).font(.caption).foregroundStyle(.secondary)
                }
            }
        }.navigationTitle("Diagnostic logs")
        .toolbar {
            ShareLink(item: visible.map { $0.date.formatted() + " " + $0.severity + " " + $0.event }.joined(separator: "\n"))
            Button("Clear", role: .destructive) { confirm = true }
        }
        .confirmationDialog("Clear diagnostic logs?", isPresented: $confirm) {
            Button("Clear", role: .destructive) { log.clear() }
        }
    }
}
