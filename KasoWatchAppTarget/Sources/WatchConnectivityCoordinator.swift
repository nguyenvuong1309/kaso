import Foundation
import KasoWidgetShared
import WatchConnectivity

/// Receives `WidgetSnapshot` updates from the paired iPhone via
/// `WCSession.updateApplicationContext` (best-effort delivery). Falls back to
/// the locally cached snapshot in the shared App Group container when the
/// session hasn't started yet or the watch was just installed.
@MainActor
final class WatchConnectivityCoordinator: NSObject, ObservableObject {
    @Published private(set) var snapshot: WidgetSnapshot

    private let delegate = WatchSessionDelegate()

    override init() {
        snapshot = WidgetSnapshotStore.load()
        super.init()
        delegate.onUpdate = { [weak self] new in
            Task { @MainActor in
                self?.snapshot = new
                WidgetSnapshotStore.save(new)
            }
        }
    }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = delegate
        session.activate()
    }
}

private final class WatchSessionDelegate: NSObject, WCSessionDelegate, @unchecked Sendable {
    var onUpdate: ((WidgetSnapshot) -> Void)?

    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}

    func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext[WidgetSnapshot.storageKey] as? Data else { return }
        guard let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else { return }
        onUpdate?(snapshot)
    }

    func session(_: WCSession, didReceiveMessageData messageData: Data) {
        guard let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: messageData) else { return }
        onUpdate?(snapshot)
    }
}
