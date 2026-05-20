import ComposableArchitecture
import KasoDesignSystem
import SmartSearchDomain
import SwiftUI

public struct SmartSearchRootView: View {
    private let store: StoreOf<SmartSearchFeature>

    public init() {
        store = Store(initialState: SmartSearchFeature.State()) {
            SmartSearchFeature()
        }
    }

    public var body: some View {
        SmartSearchView(store: store)
    }
}

public struct SmartSearchView: View {
    @Bindable private var store: StoreOf<SmartSearchFeature>

    public init(store: StoreOf<SmartSearchFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                KasoCard {
                    SmartSearchHeaderCard()
                }

                KasoCard {
                    SmartSearchInputCard(
                        text: $store.queryText.sending(\.queryTextChanged),
                        onParse: { store.send(.parseRequested) }
                    )
                }

                KasoCard {
                    SmartSearchExamplesCard(
                        onSelect: { store.send(.exampleTapped($0)) }
                    )
                }

                if let result = store.lastQuery {
                    KasoCard {
                        SmartSearchResultCard(query: result)
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
    }
}
