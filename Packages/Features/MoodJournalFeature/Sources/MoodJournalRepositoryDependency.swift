import ComposableArchitecture
import MoodJournalDomain

private enum MoodJournalRepositoryKey: DependencyKey {
    static let liveValue = MoodJournalRepository.empty
    static let previewValue = MoodJournalRepository.preview
    static let testValue = MoodJournalRepository.empty
}

public extension MoodJournalRepository {
    static let preview = MoodJournalRepository(
        fetchAll: {
            [
                MoodEntry(mood: .stressed, spendingTotalSnapshot: 650_000, note: "Stress deadline"),
                MoodEntry(mood: .good, spendingTotalSnapshot: 220_000, note: "Sáng cuối tuần"),
                MoodEntry(mood: .anxious, spendingTotalSnapshot: 480_000),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public extension DependencyValues {
    var moodJournalRepository: MoodJournalRepository {
        get { self[MoodJournalRepositoryKey.self] }
        set { self[MoodJournalRepositoryKey.self] = newValue }
    }
}
