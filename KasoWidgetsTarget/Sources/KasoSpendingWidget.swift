import KasoWidgetShared
import SwiftUI
import WidgetKit

struct KasoSpendingWidget: Widget {
    let kind = "com.vuongnguyen.kaso.widget.spending"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KasoSpendingProvider()) { entry in
            KasoSpendingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(Text("widget.spending.title", bundle: .main))
        .description(Text("widget.spending.description", bundle: .main))
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
        ])
    }
}

struct KasoSpendingEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot

    static let placeholder = KasoSpendingEntry(date: Date(), snapshot: .placeholder)
}

struct KasoSpendingProvider: TimelineProvider {
    func placeholder(in _: Context) -> KasoSpendingEntry {
        .placeholder
    }

    func getSnapshot(in _: Context, completion: @escaping (KasoSpendingEntry) -> Void) {
        completion(KasoSpendingEntry(date: Date(), snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<KasoSpendingEntry>) -> Void) {
        let entry = KasoSpendingEntry(date: Date(), snapshot: WidgetSnapshotStore.load())
        // Refresh every 30 minutes — the app also reloads the timeline whenever
        // it writes a new snapshot, so this is just a fallback heartbeat.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
