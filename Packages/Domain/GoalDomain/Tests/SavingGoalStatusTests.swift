import Foundation
import Testing
@testable import GoalDomain

@Test("status cases expose their raw string values")
func statusRawValues() {
    #expect(SavingGoalStatus.notStarted.rawValue == "notStarted")
    #expect(SavingGoalStatus.inProgress.rawValue == "inProgress")
    #expect(SavingGoalStatus.completed.rawValue == "completed")
    #expect(SavingGoalStatus.overdue.rawValue == "overdue")
}

@Test("status initializes from a known raw value")
func statusInitFromRawValue() {
    #expect(SavingGoalStatus(rawValue: "inProgress") == .inProgress)
    #expect(SavingGoalStatus(rawValue: "unknown") == nil)
}

@Test("status round-trips through Codable")
func statusCodableRoundTrip() throws {
    for status in [SavingGoalStatus.notStarted, .inProgress, .completed, .overdue] {
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(SavingGoalStatus.self, from: data)
        #expect(decoded == status)
    }
}
