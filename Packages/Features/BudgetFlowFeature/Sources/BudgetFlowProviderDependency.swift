import BudgetFlowDomain
import ComposableArchitecture
import Foundation

public struct BudgetFlowProvider: Sendable {
    public var load: @Sendable () async throws -> BudgetFlow

    public init(load: @escaping @Sendable () async throws -> BudgetFlow) {
        self.load = load
    }
}

extension BudgetFlowProvider {
    public static let empty = BudgetFlowProvider {
        BudgetFlow.empty
    }

    public static let sample = BudgetFlowProvider {
        BudgetFlowSampleData.householdMonth
    }
}

private enum BudgetFlowProviderKey: DependencyKey {
    static let liveValue: BudgetFlowProvider = .empty
    static let testValue: BudgetFlowProvider = .empty
    static let previewValue: BudgetFlowProvider = .sample
}

public extension DependencyValues {
    var budgetFlowProvider: BudgetFlowProvider {
        get { self[BudgetFlowProviderKey.self] }
        set { self[BudgetFlowProviderKey.self] = newValue }
    }
}
