import ComposableArchitecture
import Foundation
import MoneyTherapistDomain

private enum TherapistRepositoryKey: DependencyKey {
    static let liveValue = TherapistRepository.empty
    static let previewValue = TherapistRepository.preview
    static let testValue = TherapistRepository.empty
}

public extension TherapistRepository {
    static let preview = TherapistRepository(
        fetchAll: {
            [
                TherapistReflection(
                    topic: .recentOverspend,
                    note: "Cuối tuần mất kiểm soát"
                ),
                TherapistReflection(
                    topic: .guilt,
                    note: nil,
                    recordedAt: Date().addingTimeInterval(-86_400 * 3)
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public extension DependencyValues {
    var therapistRepository: TherapistRepository {
        get { self[TherapistRepositoryKey.self] }
        set { self[TherapistRepositoryKey.self] = newValue }
    }
}
