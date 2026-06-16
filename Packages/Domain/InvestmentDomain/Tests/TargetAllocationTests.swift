import Foundation
import Testing
@testable import InvestmentDomain

struct TargetAllocationTests {
    @Test("empty constant has no fractions and is valid")
    func emptyConstant() {
        #expect(TargetAllocation.empty.fractions.isEmpty)
        #expect(TargetAllocation.empty.totalFraction == 0)
        #expect(TargetAllocation.empty.isValid)
        #expect(TargetAllocation.empty.validationErrors().isEmpty)
    }

    @Test("total fraction sums all values")
    func totalFraction() {
        let allocation = TargetAllocation(fractions: [.stock: 0.6, .gold: 0.4])
        #expect(abs(allocation.totalFraction - 1.0) < 0.0001)
    }

    @Test("valid allocation summing to 1 reports no errors")
    func validAllocation() {
        let allocation = TargetAllocation(fractions: [.stock: 0.5, .gold: 0.3, .bond: 0.2])
        #expect(allocation.validationErrors().isEmpty)
        #expect(allocation.isValid)
    }

    @Test("sum within tolerance of 1 is accepted")
    func sumWithinTolerance() {
        let allocation = TargetAllocation(fractions: [.stock: 0.6005, .gold: 0.4])
        #expect(allocation.isValid)
    }

    @Test("sum outside tolerance is rejected")
    func sumOutsideTolerance() {
        let allocation = TargetAllocation(fractions: [.stock: 0.5, .gold: 0.4])
        #expect(allocation.validationErrors().contains(.sumMustEqual100Percent))
        #expect(allocation.isValid == false)
    }

    @Test("negative fraction is rejected")
    func negativeFraction() {
        let allocation = TargetAllocation(fractions: [.stock: 1.2, .gold: -0.2])
        #expect(allocation.validationErrors().contains(.fractionMustBeNonNegative))
    }

    @Test("both errors can be reported together")
    func multipleErrors() {
        let allocation = TargetAllocation(fractions: [.stock: -0.5])
        let errors = Set(allocation.validationErrors())
        #expect(errors.contains(.fractionMustBeNonNegative))
        #expect(errors.contains(.sumMustEqual100Percent))
    }

    @Test("validated returns self when valid")
    func validatedReturnsSelf() throws {
        let allocation = TargetAllocation(fractions: [.stock: 0.6, .gold: 0.4])
        let validated = try allocation.validated()
        #expect(validated == allocation)
    }

    @Test("validated throws the first error when invalid")
    func validatedThrows() {
        let allocation = TargetAllocation(fractions: [.stock: 0.5, .gold: 0.4])
        #expect(throws: TargetAllocationValidationError.self) {
            _ = try allocation.validated()
        }
    }

    @Test("codable round-trip preserves fractions")
    func codableRoundTrip() throws {
        let allocation = TargetAllocation(fractions: [.stock: 0.6, .gold: 0.4])
        let data = try JSONEncoder().encode(allocation)
        let decoded = try JSONDecoder().decode(TargetAllocation.self, from: data)
        #expect(decoded == allocation)
    }

    @Test("empty repository loads empty allocation and ignores saves")
    func emptyRepository() async throws {
        let loaded = try await TargetAllocationRepository.empty.load()
        #expect(loaded == .empty)
        try await TargetAllocationRepository.empty.save(TargetAllocation(fractions: [.stock: 1.0]))
    }
}
