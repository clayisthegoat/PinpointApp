import WidgetKit
import ActivityKit
import SwiftUI

struct PinpointEntry: TimelineEntry { let date: Date }
struct PinpointProvider: TimelineProvider {
    func placeholder(in context: Context) -> PinpointEntry { PinpointEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (PinpointEntry) -> Void) { completion(PinpointEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PinpointEntry>) -> Void) {
        completion(Timeline(entries: [PinpointEntry(date: .now)], policy: .never))
    }
}
struct PinpointWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PinpointLauncher", provider: PinpointProvider()) { _ in
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "mappin.circle.fill").font(.largeTitle).foregroundStyle(.blue)
                Text("Pinpoint").font(.headline)
                Text("Open location tools").font(.caption).foregroundStyle(.secondary)
                Text("Open app to check session").font(.caption2).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .containerBackground(for: .widget) { Color.blue.opacity(0.08) }
        }.configurationDisplayName("Pinpoint").description("Open Pinpoint from your Home Screen.").supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

struct PinpointDiagnosticActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PinpointActivityAttributes.self) { context in
            HStack {
                Image(systemName: "mappin.circle.fill").foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text("Pinpoint").font(.headline)
                    Text(context.state.status).font(.caption)
                }
                Spacer()
                Text(context.attributes.started, style: .timer).monospacedDigit()
            }.padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Image(systemName: "mappin.circle.fill").foregroundStyle(.blue) }
                DynamicIslandExpandedRegion(.trailing) { Text(context.attributes.started, style: .timer).monospacedDigit() }
                DynamicIslandExpandedRegion(.bottom) { Text(context.state.status) }
            } compactLeading: {
                Image(systemName: "mappin.circle.fill").foregroundStyle(.blue)
            } compactTrailing: {
                Text(context.attributes.started, style: .timer).monospacedDigit().frame(width: 48)
            } minimal: {
                Image(systemName: "mappin.circle.fill")
            }
        }
    }
}

@main
struct PinpointWidgetBundle: WidgetBundle {
    var body: some Widget {
        PinpointWidget()
        PinpointDiagnosticActivity()
        PinpointSimulationActivity()
    }
}

struct PinpointSimulationActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PinpointSimulationAttributes.self) { context in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Pinpoint", systemImage: "location.fill").font(.headline)
                    Spacer()
                    Text(context.attributes.started, style: .timer).monospacedDigit()
                }
                Text(context.isStale ? "Status needs verification" : context.state.status)
                Text(context.state.mode).font(.caption)
                if context.state.mode != "Stationary" { ProgressView(value: context.state.progress) }
            }.padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Image(systemName: "location.fill") }
                DynamicIslandExpandedRegion(.trailing) { Text(context.attributes.started, style: .timer) }
                DynamicIslandExpandedRegion(.bottom) { Text(context.isStale ? "Check Pinpoint" : context.state.status + " · " + context.state.mode) }
            } compactLeading: {
                Image(systemName: "location.fill")
            } compactTrailing: {
                Text(context.isStale ? "?" : "GPS")
            } minimal: {
                Image(systemName: "location.fill")
            }
        }
    }
}
