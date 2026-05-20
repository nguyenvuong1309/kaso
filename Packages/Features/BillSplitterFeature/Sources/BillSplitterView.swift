import BillSplitterDomain
import ComposableArchitecture
import KasoDesignSystem
import SwiftUI

public struct BillSplitterRootView: View {
    private let store: StoreOf<BillSplitterFeature>

    public init() {
        store = Store(initialState: BillSplitterFeature.State()) {
            BillSplitterFeature()
        }
    }

    public var body: some View {
        BillSplitterView(store: store)
    }
}

public struct BillSplitterView: View {
    @Bindable private var store: StoreOf<BillSplitterFeature>

    public init(store: StoreOf<BillSplitterFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                KasoCard {
                    BillSplitterHeaderCard(
                        title: $store.split.title.sending(\.titleChanged),
                        onReset: { store.send(.resetTapped) }
                    )
                }

                KasoCard {
                    BillSplitterParticipantsCard(
                        participants: store.split.participants,
                        payerID: store.split.payerID,
                        newName: $store.newParticipantName.sending(\.newParticipantNameChanged),
                        onAdd: { store.send(.addParticipantTapped) },
                        onRemove: { store.send(.removeParticipantTapped($0)) },
                        onSelectPayer: { store.send(.payerChanged($0)) }
                    )
                }

                KasoCard {
                    BillSplitterItemsCard(
                        items: store.split.items,
                        participants: store.split.participants,
                        newLabel: $store.newItemLabel.sending(\.newItemLabelChanged),
                        newAmount: $store.newItemAmountText.sending(\.newItemAmountChanged),
                        onAdd: { store.send(.addItemTapped) },
                        onRemove: { store.send(.removeItemTapped($0)) },
                        onToggleAssignment: { itemID, participantID in
                            store.send(
                                .toggleAssignment(itemID: itemID, participantID: participantID)
                            )
                        }
                    )
                }

                KasoCard {
                    BillSplitterTipCard(
                        tipMode: store.split.tipMode,
                        onChange: { store.send(.tipModeChanged($0)) }
                    )
                }

                KasoCard {
                    BillSplitterSummaryCard(
                        result: store.result,
                        shareText: store.shareText
                    )
                }

                if let messageKey = store.errorMessageKey {
                    BillSplitterErrorLabel(messageKey: messageKey)
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
    }
}

private struct BillSplitterErrorLabel: View {
    let messageKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(messageKey), bundle: .module)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .font(.kaso.caption)
        .foregroundStyle(Color.kaso.destructive)
        .padding(Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(Color.kaso.destructive.opacity(0.12))
        )
    }
}
