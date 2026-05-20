import ComposableArchitecture
import RemindersDomain

private enum ReminderRepositoryKey: DependencyKey {
    static let liveValue = ReminderRepository.empty
    static let previewValue = ReminderRepository.preview
    static let testValue = ReminderRepository.empty
}

public extension ReminderRepository {
    static let preview = ReminderRepository(
        load: { .default },
        save: { _ in }
    )
}

public extension DependencyValues {
    var reminderRepository: ReminderRepository {
        get { self[ReminderRepositoryKey.self] }
        set { self[ReminderRepositoryKey.self] = newValue }
    }
}
