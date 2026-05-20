import Foundation
import Testing
@testable import BNPLDomain

struct BNPLDomainTests {
    @Test("BNPLInstallmentBuilder generates monthly installments")
    func generateMonthlyInstallments() {
        let start = Date()
        let installments = BNPLInstallmentBuilder.generateMonthly(
            totalAmount: 3_000_000,
            installmentCount: 3,
            startDate: start
        )

        #expect(installments.count == 3)
        #expect(installments.allSatisfy { $0.amount == 1_000_000 })
        #expect(installments.allSatisfy { $0.isPaid == false })
    }

    @Test("BNPLObligation.remainingAmount excludes paid installments")
    func remainingAmountCalculation() {
        var installments = BNPLInstallmentBuilder.generateMonthly(
            totalAmount: 3_000_000,
            installmentCount: 3,
            startDate: Date()
        )
        installments[0].isPaid = true

        let obligation = BNPLObligation(
            provider: .shopeePayLater,
            purchaseName: "Test",
            totalAmount: 3_000_000,
            purchaseDate: Date(),
            installmentCount: 3,
            installments: installments
        )

        #expect(obligation.remainingAmount == 2_000_000)
        #expect(obligation.paidAmount == 1_000_000)
    }

    @Test("BNPLObligation.status returns completed when all paid")
    func statusCompleted() {
        let installments = [
            BNPLInstallment(dueDate: Date(), amount: 1_000_000, isPaid: true),
            BNPLInstallment(dueDate: Date(), amount: 1_000_000, isPaid: true),
        ]
        let obligation = BNPLObligation(
            provider: .atome,
            purchaseName: "Test",
            totalAmount: 2_000_000,
            purchaseDate: Date(),
            installmentCount: 2,
            installments: installments
        )

        #expect(obligation.status() == .completed)
    }

    @Test("BNPLObligation.status returns overdue when past unpaid installment exists")
    func statusOverdue() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let installments = [
            BNPLInstallment(dueDate: yesterday, amount: 1_000_000, isPaid: false),
        ]
        let obligation = BNPLObligation(
            provider: .shopeePayLater,
            purchaseName: "Test",
            totalAmount: 1_000_000,
            purchaseDate: yesterday,
            installmentCount: 1,
            installments: installments
        )

        #expect(obligation.status(at: Date()) == .overdue)
    }

    @Test("BNPLHealth evaluates risk levels correctly")
    func healthEvaluation() {
        #expect(BNPLHealth.evaluate(monthlyObligation: 500_000, monthlyIncome: 20_000_000) == .safe)
        #expect(BNPLHealth.evaluate(monthlyObligation: 3_000_000, monthlyIncome: 20_000_000) == .caution)
        #expect(BNPLHealth.evaluate(monthlyObligation: 5_000_000, monthlyIncome: 20_000_000) == .overexposed)
        #expect(BNPLHealth.evaluate(monthlyObligation: 8_000_000, monthlyIncome: 20_000_000) == .critical)
        #expect(BNPLHealth.evaluate(monthlyObligation: 1_000_000, monthlyIncome: 0) == .critical)
    }

    @Test("BNPLSummaryBuilder aggregates totals correctly")
    func summaryAggregation() {
        let calendar = Calendar.current
        let now = Date()
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) ?? now

        let obligation = BNPLObligation(
            provider: .shopeePayLater,
            purchaseName: "Test",
            totalAmount: 3_000_000,
            purchaseDate: now,
            installmentCount: 3,
            installments: [
                BNPLInstallment(dueDate: now, amount: 1_000_000, isPaid: false),
                BNPLInstallment(dueDate: nextMonth, amount: 1_000_000, isPaid: false),
                BNPLInstallment(
                    dueDate: calendar.date(byAdding: .month, value: 2, to: now) ?? now,
                    amount: 1_000_000,
                    isPaid: false
                ),
            ]
        )

        let summary = BNPLSummaryBuilder.build(
            obligations: [obligation],
            monthlyIncome: 20_000_000,
            referenceDate: now
        )

        #expect(summary.totalActiveObligations == 1)
        #expect(summary.totalOutstanding == 3_000_000)
        #expect(summary.currentMonthDue == 1_000_000)
        #expect(summary.nextThreeMonthsDue == 3_000_000)
        #expect(summary.health == .safe)
    }
}
