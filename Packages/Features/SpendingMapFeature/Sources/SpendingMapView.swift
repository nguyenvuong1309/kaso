import ComposableArchitecture
import KasoDesignSystem
import MapKit
import SpendingMapDomain
import SwiftUI

public struct SpendingMapView: View {
    @Bindable private var store: StoreOf<SpendingMapFeature>
    @State private var mapPosition: MapCameraPosition

    public init(store: StoreOf<SpendingMapFeature>) {
        self.store = store
        _mapPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: SpendingMapFeature.defaultLatitude,
                        longitude: SpendingMapFeature.defaultLongitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
                )
            )
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if let messageKey = store.errorMessageKey {
                    SpendingMapErrorLabel(messageKey: messageKey)
                }

                KasoCard {
                    SpendingMapHeaderCard(
                        summary: store.summary,
                        period: store.period,
                        onPeriodChanged: { store.send(.periodChanged($0)) },
                        onAddTapped: { store.send(.addButtonTapped) }
                    )
                }

                KasoCard {
                    SpendingMapPreview(
                        hotspots: store.summary.hotspots,
                        position: $mapPosition
                    )
                }

                if store.entries.isEmpty {
                    KasoCard {
                        SpendingMapEmptyStateCard()
                    }
                } else {
                    SpendingMapEntryList(
                        entries: Array(store.entries),
                        onEdit: { store.send(.editButtonTapped($0)) },
                        onDelete: { store.send(.deleteButtonTapped($0)) }
                    )
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
        .task {
            await store.send(.task).finish()
        }
        .sheet(isPresented: Binding(
            get: { store.isEditorPresented },
            set: { if !$0 { store.send(.editorDismissed) } }
        )) {
            SpendingMapEditorSheet(store: store)
        }
    }
}

private struct SpendingMapErrorLabel: View {
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
