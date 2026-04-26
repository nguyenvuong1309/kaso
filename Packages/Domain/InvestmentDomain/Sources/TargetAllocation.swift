import Foundation

public enum TargetAllocationValidationError: String, Error, Codable, Equatable, Sendable {
    case sumMustEqual100Percent
    case fractionMustBeNonNegative
}

public struct TargetAllocation: Codable, Equatable, Sendable {
    public var fractions: [AssetClass: Double]

    public init(fractions: [AssetClass: Double]) {
        self.fractions = fractions
    }

    public static let empty = TargetAllocation(fractions: [:])

    public var totalFraction: Double {
        fractions.values.reduce(0, +)
    }

    public var isValid: Bool {
        validationErrors().isEmpty
    }

    public func validationErrors() -> [TargetAllocationValidationError] {
        var errors: [TargetAllocationValidationError] = []
        if fractions.contains(where: { $0.value < 0 }) {
            errors.append(.fractionMustBeNonNegative)
        }
        if !fractions.isEmpty && abs(totalFraction - 1.0) > 0.001 {
            errors.append(.sumMustEqual100Percent)
        }
        return errors
    }

    public func validated() throws -> TargetAllocation {
        if let firstError = validationErrors().first {
            throw firstError
        }
        return self
    }
}

public struct TargetAllocationRepository: Sendable {
    public var load: @Sendable () async throws -> TargetAllocation
    public var save: @Sendable (TargetAllocation) async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> TargetAllocation,
        save: @escaping @Sendable (TargetAllocation) async throws -> Void
    ) {
        self.load = load
        self.save = save
    }
}

public extension TargetAllocationRepository {
    static let empty = TargetAllocationRepository(
        load: { .empty },
        save: { _ in }
    )
}
