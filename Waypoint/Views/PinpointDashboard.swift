import SwiftUI
import MapKit

struct RouteDashboard: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 8) {
                Label(model.routePaused ? "Paused" : (model.routeWalking ? "Walk Mode" : "Drive Mode"), systemImage: model.routeWalking ? "figure.walk" : "car.fill").font(.headline)
                HStack {
                    metric("Speed (target)", String(format: "%.0f mph", model.routePaused ? 0 : model.routeSpeed / 1.609344))
                    Spacer()
                    metric("Remaining", String(format: "%.1f mi", model.routeDistance * (1-model.routeProgress) / 1609.344))
                    Spacer()
                    metric("Elapsed", String(format: "%d min", max(0, Int(context.date.timeIntervalSince(model.routeStarted ?? context.date)/60))))
                }
                ProgressView(value: model.routeProgress)
                if model.routeSpeed > 0 && !model.routePaused {
                    Text(String(format: "Estimated remaining: %.0f min", model.routeDistance * (1-model.routeProgress) / (model.routeSpeed / 3.6) / 60)).font(.caption)
                }
            }.padding(12).background(.regularMaterial)
        }
    }
    private func metric(_ name: String, _ value: String) -> some View {
        VStack(alignment: .leading) {
            Text(name).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold()).monospacedDigit()
        }
    }
}

extension MapSpoofView {
    var homeShortcuts: some View {
        HStack(spacing: 8) {
            ForEach(shortcutOrder.split(separator: ",").map(String.init), id: \.self) { id in
                if let item = PinpointShortcut.all.first(where: { $0.id == id }) {
                    shortcut(item.title, item.symbol, item.id)
                }
            }
        }.padding(.horizontal, 12).padding(.vertical, 10).background(.ultraThinMaterial)
        .sheet(item: Binding(get: { homeDestination.map { HomeShortcut(id: $0) } }, set: { homeDestination = $0?.id })) { item in
            NavigationStack {
                Group {
                    switch item.id {
                    case "favorites":
                        FavoriteLocationsView(data: $namedFavoritesData, selection: selection) { coordinate in
                            select(coordinate.coreLocationCoordinate)
                            cameraPosition = .region(MKCoordinateRegion(center: coordinate.coreLocationCoordinate, latitudinalMeters: 2000, longitudinalMeters: 2000))
                            homeDestination = nil
                        }
                    case "diagnostics": PinpointDiagnosticsView()
                    case "history": PinpointHistoryView(data: $historyData) { coordinate in
                        select(coordinate.coreLocationCoordinate)
                        cameraPosition = .region(MKCoordinateRegion(center: coordinate.coreLocationCoordinate, latitudinalMeters: 2000, longitudinalMeters: 2000))
                        homeDestination = nil
                    }
                    case "changelog": PinpointChangelogView()
                    case "settings": PinpointPreferences()
                    default:
                        DriveModeView(initial: selection, favorites: (try? JSONDecoder().decode([PinpointPlace].self, from: namedFavoritesData)) ?? [], walking: item.id == "walk")
                    }
                }.toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { homeDestination = nil } } }
            }.environmentObject(model)
                .tint(interfaceAccent)
                .accentColor(interfaceAccent)
        }
    }
    private func shortcut(_ title: String, _ symbol: String, _ destination: String) -> some View {
        Button { homeDestination = destination } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 21, weight: .semibold))
                Text(title).font(.caption2.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.75)
            }.frame(maxWidth: .infinity, minHeight: 58).padding(.horizontal, 3)
        }.buttonStyle(PinpointShortcutButtonStyle(accent: interfaceAccent))
            .sensoryFeedback(.selection, trigger: homeDestination) { _, new in interfaceHaptics && new != nil }
    }
}

struct HomeShortcut: Identifiable { let id: String }

struct PinpointDiagnosticsView: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        Form {
            Section("Readiness") {
                check("Pairing record", model.pairingState.isReady, "Import a valid pairing record in Settings.")
                check("Developer tunnel", model.tunnelState.isReady, "Connect LocalDevVPN and prepare the device.")
                check("Developer image", model.developerImageState.isReady, "Prepare the developer image in Settings.")
                check("LocalDevVPN installed", model.isLocalDevVPNInstalled, "Install LocalDevVPN. Installation does not confirm VPN connectivity.")
                check("SideStore available", model.isSideStoreAvailable, "Check SideStore installation and refresh your app.")
            }
            DiagnosticsActivityView()
            Section("Tests") {
                NavigationLink("Diagnostic logs") { PinpointLogView() }
                NavigationLink("Network check") { NetworkCheckView().environmentObject(model) }
                NavigationLink("Location diagnostics") { LocationDiagnosticsView() }
            }
            Section("Session") {
                LabeledContent("Simulation", value: model.simulatedCoordinate == nil ? "Inactive" : "Active")
                LabeledContent("Location writes", value: model.areLocationWritesPausedForCellularHandoff ? "Paused" : "Not paused")
                LabeledContent("Keepalive", value: model.backgroundKeepAliveEnabled ? "Enabled" : "Disabled")
                if !model.preparationMessage.isEmpty { Text(model.preparationMessage).font(.caption) }
                Text("These are reported app states, not an independent network probe.").font(.caption).foregroundStyle(.secondary)
            }
        }.navigationTitle("Diagnostics")
    }
    private func check(_ name: String, _ ready: Bool, _ help: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(name, systemImage: ready ? "checkmark.circle.fill" : "exclamationmark.circle").foregroundStyle(ready ? Color.green : Color.orange)
            if !ready { Text(help).font(.caption).foregroundStyle(.secondary) }
        }
    }
}
