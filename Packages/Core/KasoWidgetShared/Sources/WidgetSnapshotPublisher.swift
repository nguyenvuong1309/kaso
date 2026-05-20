import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Publishes a fresh `WidgetSnapshot` to the shared App Group container so
/// installed widgets and Live Activities can read the latest summary without
/// touching the encrypted transaction store.
public actor WidgetSnapshotPublisher {
    private let defaults: UserDefaults?

    public init(suiteName: String = WidgetSnapshot.appGroupID) {
        defaults = UserDefaults(suiteName: suiteName)
    }

    public func publish(_ snapshot: WidgetSnapshot) async {
        WidgetSnapshotStore.save(snapshot, into: defaults)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
        await MainActor.run {
            WatchSnapshotSender.shared.send(snapshot)
        }
    }

    public func currentSnapshot() -> WidgetSnapshot {
        WidgetSnapshotStore.load(from: defaults)
    }
}
