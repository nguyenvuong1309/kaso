import BillSplitterDomain
import ComposableArchitecture
import Foundation

@Reducer
public struct BillSplitterFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var split: BillSplit
        public var newParticipantName: String
        public var newItemLabel: String
        public var newItemAmountText: String
        public var errorMessageKey: String?

        public init(
            split: BillSplit = BillSplit(),
            newParticipantName: String = "",
            newItemLabel: String = "",
            newItemAmountText: String = "",
            errorMessageKey: String? = nil
        ) {
            self.split = split
            self.newParticipantName = newParticipantName
            self.newItemLabel = newItemLabel
            self.newItemAmountText = newItemAmountText
            self.errorMessageKey = errorMessageKey
        }

        public var result: BillSplitResult {
            BillSplitCalculator.calculate(split: split)
        }

        public var shareText: String {
            let lines = result.settlements.map { settlement in
                "\(settlement.fromName) → \(settlement.toName): "
                    + settlement.amount.formatted(.currency(code: "VND"))
            }
            return lines.joined(separator: "\n")
        }
    }

    public enum Action: Equatable, Sendable {
        case titleChanged(String)
        case newParticipantNameChanged(String)
        case addParticipantTapped
        case removeParticipantTapped(UUID)
        case payerChanged(UUID?)
        case tipModeChanged(BillTipMode)
        case newItemLabelChanged(String)
        case newItemAmountChanged(String)
        case addItemTapped
        case removeItemTapped(UUID)
        case toggleAssignment(itemID: UUID, participantID: UUID)
        case resetTapped
    }

    @Dependency(\.uuid) private var uuid

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .titleChanged(text):
                state.split.title = text
                return .none

            case let .newParticipantNameChanged(text):
                state.newParticipantName = text
                return .none

            case .addParticipantTapped:
                let trimmed = state.newParticipantName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.isEmpty == false else {
                    state.errorMessageKey = "billSplitter.error.emptyName"
                    return .none
                }
                let participant = BillParticipant(id: uuid(), name: trimmed)
                state.split.participants.append(participant)
                state.newParticipantName = ""
                state.errorMessageKey = nil
                if state.split.payerID == nil {
                    state.split.payerID = participant.id
                }
                return .none

            case let .removeParticipantTapped(id):
                state.split.participants.removeAll { $0.id == id }
                state.split.items = state.split.items.map { item in
                    var copy = item
                    copy.assignedTo.removeAll { $0 == id }
                    return copy
                }
                if state.split.payerID == id {
                    state.split.payerID = state.split.participants.first?.id
                }
                return .none

            case let .payerChanged(id):
                state.split.payerID = id
                return .none

            case let .tipModeChanged(mode):
                state.split.tipMode = mode
                return .none

            case let .newItemLabelChanged(text):
                state.newItemLabel = text
                return .none

            case let .newItemAmountChanged(text):
                state.newItemAmountText = text
                return .none

            case .addItemTapped:
                let label = state.newItemLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                guard label.isEmpty == false else {
                    state.errorMessageKey = "billSplitter.error.emptyItemLabel"
                    return .none
                }
                guard let amount = parseAmount(state.newItemAmountText), amount > 0 else {
                    state.errorMessageKey = "billSplitter.error.invalidAmount"
                    return .none
                }
                let item = BillItem(id: uuid(), label: label, amount: amount)
                state.split.items.append(item)
                state.newItemLabel = ""
                state.newItemAmountText = ""
                state.errorMessageKey = nil
                return .none

            case let .removeItemTapped(id):
                state.split.items.removeAll { $0.id == id }
                return .none

            case let .toggleAssignment(itemID, participantID):
                guard let index = state.split.items.firstIndex(where: { $0.id == itemID })
                else { return .none }
                var item = state.split.items[index]
                if item.assignedTo.contains(participantID) {
                    item.assignedTo.removeAll { $0 == participantID }
                } else {
                    item.assignedTo.append(participantID)
                }
                state.split.items[index] = item
                return .none

            case .resetTapped:
                state.split = BillSplit()
                state.newParticipantName = ""
                state.newItemLabel = ""
                state.newItemAmountText = ""
                state.errorMessageKey = nil
                return .none
            }
        }
    }

    private func parseAmount(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        if cleaned.isEmpty { return nil }
        return Decimal(string: cleaned)
    }
}
