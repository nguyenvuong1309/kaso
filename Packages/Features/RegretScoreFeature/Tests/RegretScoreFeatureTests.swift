import ComposableArchitecture
import Foundation
import RegretScoreDomain
import Testing
@testable import RegretScoreFeature

@MainActor
@Test("loads ratings and reminders on task")
func loadsRatingsAndReminders() async throws {
    let referenceDate = Date(timeIntervalSince1970: 30 * 86_400)
    let rating = RegretRating(
        purchaseTitle: "Sneaker",
        category: "fashion",
        amount: 2_500_000,
        score: .regret,
        purchasedAt: referenceDate.addingTimeInterval(-15 * 86_400),
        ratedAt: referenceDate.addingTimeInterval(-7 * 86_400)
    )
    let reminderInput = RegretReminderInput(
        transactionID: UUID(),
        title: "Jacket",
        category: "fashion",
        amount: 1_500_000,
        occurredAt: referenceDate.addingTimeInterval(-10 * 86_400)
    )
    let store = TestStore(initialState: RegretScoreFeature.State()) {
        RegretScoreFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.regretRatingRepository.fetchAll = { [rating] }
        $0.regretReminderContextClient.fetchCandidates = { [reminderInput] }
    }

    await store.send(.task) {
        $0.referenceDate = referenceDate
        $0.isLoading = true
    }
    let expectedReminders = RegretReminderBuilder.reminders(
        from: [reminderInput],
        ratings: [rating],
        referenceDate: Date()
    )
    await store.receive(.dataLoaded(ratings: [rating], reminders: expectedReminders)) {
        $0.isLoading = false
        $0.ratings = IdentifiedArray(uniqueElements: [rating])
        $0.reminders = IdentifiedArray(uniqueElements: expectedReminders)
    }
}

@MainActor
@Test("rating a reminder prefills the editor and removes the reminder when saved")
func ratingReminderPrefillsEditor() async throws {
    let referenceDate = Date(timeIntervalSince1970: 30 * 86_400)
    let ratingID = try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))
    let candidate = RegretReminderCandidate(
        transactionID: UUID(),
        title: "Jacket",
        category: "fashion",
        amount: 1_500_000,
        occurredAt: referenceDate.addingTimeInterval(-10 * 86_400)
    )
    let saved = LockIsolated<[RegretRating]>([])
    let store = TestStore(
        initialState: RegretScoreFeature.State(
            reminders: IdentifiedArray(uniqueElements: [candidate])
        )
    ) {
        RegretScoreFeature()
    } withDependencies: {
        $0.date.now = referenceDate
        $0.uuid = UUIDGenerator { ratingID }
        $0.regretRatingRepository.save = { rating in
            saved.withValue { $0.append(rating) }
        }
    }

    await store.send(.rateReminderTapped(candidate)) {
        $0.isEditorPresented = true
        $0.prefilledFromReminderID = candidate.id
        $0.titleText = "Jacket"
        $0.categoryText = "fashion"
        $0.amountText = candidate.amount.formatted(.number.grouping(.automatic))
        $0.purchasedAt = candidate.occurredAt
        $0.score = .neutral
    }
    await store.send(.scoreChanged(.regret)) {
        $0.score = .regret
    }

    let expected = RegretRating(
        id: ratingID,
        purchaseTitle: "Jacket",
        category: "fashion",
        amount: 1_500_000,
        score: .regret,
        purchasedAt: candidate.occurredAt,
        ratedAt: referenceDate
    )

    await store.send(.saveButtonTapped) {
        $0.isEditorPresented = false
        $0.prefilledFromReminderID = nil
        $0.reminders.remove(id: candidate.id)
    }
    await store.receive(.ratingSaved(expected)) {
        $0.ratings = IdentifiedArray(uniqueElements: [expected])
    }

    #expect(saved.value == [expected])
}

@MainActor
@Test("invalid amount surfaces error key")
func invalidAmountSurfacesError() async {
    let store = TestStore(
        initialState: RegretScoreFeature.State(
            isEditorPresented: true,
            titleText: "Item",
            amountText: "0"
        )
    ) {
        RegretScoreFeature()
    }

    await store.send(.saveButtonTapped) {
        $0.editorErrorMessageKey = "regret.error.amountMustBePositive"
    }
}
