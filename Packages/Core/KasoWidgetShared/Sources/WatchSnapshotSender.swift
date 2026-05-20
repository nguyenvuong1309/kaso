import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity

/// Pushes a `WidgetSnapshot` from iPhone to the paired Apple Watch using
/// `WCSession.updateApplicationContext`. Safe to call when no watch is
/// paired — the session simply ignores updates.
@MainActor
public final class WatchSnapshotSender: NSObject {
    public static let shared = WatchSnapshotSender()

    private let delegate = SilentSessionDelegate()
    private var didActivate = false

    override private init() {
        super.init()
    }

    public func start() {
        guard WCSession.isSupported(), didActivate == false else { return }
        let session = WCSession.default
        session.delegate = delegate
        session.activate()
        didActivate = true
    }

    public func send(_ snapshot: WidgetSnapshot) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else {
            start()
            return
        }
        guard session.isPaired, session.isWatchAppInstalled else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        do {
            try session.updateApplicationContext([WidgetSnapshot.storageKey: data])
        } catch {
            // Best-effort delivery — the next refresh tick will retry.
        }
    }
}

private final class SilentSessionDelegate: NSObject, WCSessionDelegate, @unchecked Sendable {
    func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}
    #if os(iOS)
    func sessionDidBecomeInactive(_: WCSession) {}
    func sessionDidDeactivate(_: WCSession) {
        WCSession.default.activate()
    }
    #endif
}
#else
@MainActor
public final class WatchSnapshotSender {
    public static let shared = WatchSnapshotSender()

    public func start() {}
    public func send(_: WidgetSnapshot) {}
}
#endif
