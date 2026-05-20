import BudgetFlowDomain
import ComposableArchitecture
import Foundation

public enum BudgetFlowDisplayMode: String, Equatable, Sendable, CaseIterable, Identifiable {
    case amount
    case percent

    public var id: String { rawValue }

    public var titleKey: String {
        switch self {
        case .amount: "budgetFlow.mode.amount"
        case .percent: "budgetFlow.mode.percent"
        }
    }
}

@Reducer
public struct BudgetFlowFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var flow: BudgetFlow
        public var displayMode: BudgetFlowDisplayMode
        public var selectedNodeID: String?
        public var isLoading: Bool
        public var errorMessageKey: String?

        public init(
            flow: BudgetFlow = .empty,
            displayMode: BudgetFlowDisplayMode = .amount,
            selectedNodeID: String? = nil,
            isLoading: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.flow = flow
            self.displayMode = displayMode
            self.selectedNodeID = selectedNodeID
            self.isLoading = isLoading
            self.errorMessageKey = errorMessageKey
        }

        public var selectedNode: BudgetFlowNode? {
            guard let id = selectedNodeID else {
                return nil
            }
            return flow.nodes.first { $0.id == id }
        }
    }

    public enum Action: Equatable, Sendable {
        case task
        case flowLoaded(BudgetFlow)
        case loadFailed(String)
        case displayModeToggled
        case displayModeSelected(BudgetFlowDisplayMode)
        case nodeTapped(String)
        case selectionCleared
    }

    @Dependency(\.budgetFlowProvider) private var provider

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessageKey = nil
                return .run { send in
                    do {
                        let flow = try await provider.load()
                        await send(.flowLoaded(flow))
                    } catch {
                        await send(.loadFailed("budgetFlow.error.loadFailed"))
                    }
                }

            case let .flowLoaded(flow):
                state.isLoading = false
                state.flow = flow
                if let id = state.selectedNodeID, flow.nodes.contains(where: { $0.id == id }) == false {
                    state.selectedNodeID = nil
                }
                return .none

            case let .loadFailed(messageKey):
                state.isLoading = false
                state.errorMessageKey = messageKey
                return .none

            case .displayModeToggled:
                state.displayMode = state.displayMode == .amount ? .percent : .amount
                return .none

            case let .displayModeSelected(mode):
                state.displayMode = mode
                return .none

            case let .nodeTapped(id):
                state.selectedNodeID = state.selectedNodeID == id ? nil : id
                return .none

            case .selectionCleared:
                state.selectedNodeID = nil
                return .none
            }
        }
    }
}
