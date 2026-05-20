import ComposableArchitecture
import RemindersDomain

private enum ReminderSchedulerKey: DependencyKey {
    static let liveValue = ReminderScheduler.live
    static let previewValue = ReminderScheduler.empty
    static let testValue = ReminderScheduler.empty
}

public extension DependencyValues {
    var reminderScheduler: ReminderScheduler {
        get { self[ReminderSchedulerKey.self] }
        set { self[ReminderSchedulerKey.self] = newValue }
    }
}
