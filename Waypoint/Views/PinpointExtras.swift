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
    @State private var search = ""
    private struct Release: Identifiable {
        let version: String
        var notes: [String]
        var id: String { version }
    }
    private var releases: [Release] {
        guard let url = Bundle.main.url(forResource: "CHANGELOG", withExtension: "md"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        var result: [Release] = []
        for line in raw.components(separatedBy: .newlines) {
            if line.hasPrefix("## ") {
                result.append(Release(version: String(line.dropFirst(3)), notes: []))
            } else if !result.isEmpty && !line.trimmingCharacters(in: .whitespaces).isEmpty {
                result[result.count - 1].notes.append(line.hasPrefix("- ") ? String(line.dropFirst(2)) : line)
            }
        }
        return result
    }
    private var visible: [Release] {
        releases.filter { search.isEmpty || $0.version.localizedCaseInsensitiveContains(search) || $0.notes.joined(separator: " ").localizedCaseInsensitiveContains(search) }
    }
    var body: some View {
        List {
            Section {
                LabeledContent("Installed", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")
                LabeledContent("Release history", value: String(releases.count) + " versions")
            }
            if releases.isEmpty {
                ContentUnavailableView("Release notes unavailable", systemImage: "doc.text")
            } else if visible.isEmpty {
                ContentUnavailableView.search(text: search)
            }
            ForEach(visible) { release in
                Section("Version " + release.version) {
                    ForEach(Array(release.notes.enumerated()), id: \.offset) { entry in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "circle.fill").font(.system(size: 5)).padding(.top, 7).foregroundStyle(Color.accentColor)
                            Text(entry.element).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .navigationTitle("Changelog")
        .searchable(text: $search, prompt: "Search versions or changes")
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
