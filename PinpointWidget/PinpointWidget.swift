import WidgetKit
import SwiftUI

struct PinpointEntry: TimelineEntry { let date: Date }
struct PinpointProvider: TimelineProvider {
    func placeholder(in context: Context) -> PinpointEntry { PinpointEntry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (PinpointEntry) -> Void) { completion(PinpointEntry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<PinpointEntry>) -> Void) {
        completion(Timeline(entries: [PinpointEntry(date: .now)], policy: .never))
    }
}
@main
struct PinpointWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PinpointLauncher", provider: PinpointProvider()) { _ in
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "mappin.circle.fill").font(.largeTitle).foregroundStyle(.blue)
                Text("Pinpoint").font(.headline)
                Text("Open location tools").font(.caption).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .containerBackground(for: .widget) { Color.blue.opacity(0.08) }
        }.configurationDisplayName("Pinpoint").description("Open Pinpoint from your Home Screen.").supportedFamilies([.systemSmall, .systemMedium])
    }
}
