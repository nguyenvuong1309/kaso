import Foundation

public struct SavingGoal: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var targetAmount: Decimal
    public var currentAmount: Decimal
    public var deadline: Date
    public var createdAt: Date
    public var imageIdentifier: String?

    public init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Decimal,
        currentAmount: Decimal = 0,
        deadline: Date,
        createdAt: Date = Date(),
        imageIdentifier: String? = nil
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.createdAt = createdAt
        self.imageIdentifier = imageIdentifier
    }

    public var progress: SavingGoalProgress {
        SavingGoalProgress(
            currentAmount: currentAmount,
            targetAmount: targetAmount
        )
    }

    public func status(
        on date: Date = Date(),
        calendar: Calendar = .current
    ) -> SavingGoalStatus {
        if progress.isCompleted {
            return .completed
        }

        if calendar.compare(date, to: deadline, toGranularity: .day) == .orderedDescending {
            return .overdue
        }

        if currentAmount <= 0 {
            return .notStarted
        }

        return .inProgress
    }

    public func monthlyRequiredSaving(
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> Decimal {
        let remainingAmount = progress.remainingAmount
        guard remainingAmount > 0 else {
            return 0
        }

        return remainingAmount / Decimal(monthsRemaining(asOf: date, calendar: calendar))
    }

    private func monthsRemaining(
        asOf date: Date,
        calendar: Calendar
    ) -> Int {
        guard
            let currentMonth = calendar.dateInterval(of: .month, for: date)?.start,
            let deadlineMonth = calendar.dateInterval(of: .month, for: deadline)?.start
        else {
            return 1
        }

        let monthDelta = calendar.dateComponents(
            [.month],
            from: currentMonth,
            to: deadlineMonth
        ).month ?? 0
        return max(monthDelta + 1, 1)
    }
}
