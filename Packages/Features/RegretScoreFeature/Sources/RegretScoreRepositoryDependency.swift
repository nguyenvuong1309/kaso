import ComposableArchitecture
import Foundation
import RegretScoreDomain

private enum RegretRatingRepositoryKey: DependencyKey {
    static let liveValue = RegretRatingRepository.empty
    static let previewValue = RegretRatingRepository.preview
    static let testValue = RegretRatingRepository.empty
}

private enum RegretReminderContextClientKey: DependencyKey {
    static let liveValue = RegretReminderContextClient.empty
    static let previewValue = RegretReminderContextClient.preview
    static let testValue = RegretReminderContextClient.empty
}

public extension RegretRatingRepository {
    static let preview = RegretRatingRepository(
        fetchAll: {
            [
                RegretRating(
                    purchaseTitle: "Sneaker mới",
                    category: "fashion",
                    amount: 2_500_000,
                    score: .strongRegret,
                    purchasedAt: .now.addingTimeInterval(-12 * 86_400)
                ),
                RegretRating(
                    purchaseTitle: "Coffee subscription",
                    category: "food",
                    amount: 180_000,
                    score: .noRegret,
                    purchasedAt: .now.addingTimeInterval(-8 * 86_400)
                ),
            ]
        },
        save: { _ in },
        delete: { _ in }
    )
}

public extension RegretReminderContextClient {
    static let preview = RegretReminderContextClient(
        fetchCandidates: {
            [
                RegretReminderInput(
                    transactionID: UUID(),
                    title: "Áo khoác phối đồ",
                    category: "fashion",
                    amount: 1_200_000,
                    occurredAt: .now.addingTimeInterval(-10 * 86_400)
                ),
                RegretReminderInput(
                    transactionID: UUID(),
                    title: "Tai nghe noise cancelling",
                    category: "electronics",
                    amount: 6_300_000,
                    occurredAt: .now.addingTimeInterval(-14 * 86_400)
                ),
            ]
        }
    )
}

public extension DependencyValues {
    var regretRatingRepository: RegretRatingRepository {
        get { self[RegretRatingRepositoryKey.self] }
        set { self[RegretRatingRepositoryKey.self] = newValue }
    }

    var regretReminderContextClient: RegretReminderContextClient {
        get { self[RegretReminderContextClientKey.self] }
        set { self[RegretReminderContextClientKey.self] = newValue }
    }
}
