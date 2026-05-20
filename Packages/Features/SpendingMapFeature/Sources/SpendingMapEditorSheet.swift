import ComposableArchitecture
import KasoDesignSystem
import MapKit
import SpendingMapDomain
import SwiftUI

struct SpendingMapEditorSheet: View {
    @Bindable var store: StoreOf<SpendingMapFeature>
    @State private var cameraPosition: MapCameraPosition

    init(store: StoreOf<SpendingMapFeature>) {
        self.store = store
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: store.draftLatitude,
                        longitude: store.draftLongitude
                    ),
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(
                        text: Binding(
                            get: { store.draftLabel },
                            set: { store.send(.labelChanged($0)) }
                        )
                    ) {
                        Text("spendingMap.editor.label", bundle: .module)
                    }

                    let amountField = TextField(
                        text: Binding(
                            get: { store.draftAmountText },
                            set: { store.send(.amountTextChanged($0)) }
                        )
                    ) {
                        Text("spendingMap.editor.amount", bundle: .module)
                    }
                    #if os(iOS)
                    amountField.keyboardType(.numberPad)
                    #else
                    amountField
                    #endif

                    TextField(
                        text: Binding(
                            get: { store.draftCategoryID },
                            set: { store.send(.categoryChanged($0)) }
                        )
                    ) {
                        Text("spendingMap.editor.category", bundle: .module)
                    }
                    .autocorrectionDisabled()

                    DatePicker(
                        selection: Binding(
                            get: { store.draftOccurredAt },
                            set: { store.send(.occurredAtChanged($0)) }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Text("spendingMap.editor.date", bundle: .module)
                    }

                    TextField(
                        text: Binding(
                            get: { store.draftNote },
                            set: { store.send(.noteChanged($0)) }
                        ),
                        axis: .vertical
                    ) {
                        Text("spendingMap.editor.note", bundle: .module)
                    }
                    .lineLimit(2 ... 4)
                } header: {
                    Text("spendingMap.editor.section.details", bundle: .module)
                }

                Section {
                    SpendingMapDraftPicker(
                        latitude: Binding(
                            get: { store.draftLatitude },
                            set: { store.send(.coordinateChanged(latitude: $0, longitude: store.draftLongitude)) }
                        ),
                        longitude: Binding(
                            get: { store.draftLongitude },
                            set: { store.send(.coordinateChanged(latitude: store.draftLatitude, longitude: $0)) }
                        ),
                        cameraPosition: $cameraPosition
                    )
                } header: {
                    Text("spendingMap.editor.section.location", bundle: .module)
                } footer: {
                    Text("spendingMap.editor.location.hint", bundle: .module)
                }

                if let messageKey = store.editorErrorMessageKey {
                    Section {
                        Label {
                            Text(LocalizedStringKey(messageKey), bundle: .module)
                        } icon: {
                            Image(systemName: "exclamationmark.circle.fill")
                        }
                        .foregroundStyle(Color.kaso.destructive)
                    }
                }
            }
            .navigationTitle(Text("spendingMap.editor.title", bundle: .module))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.editorDismissed)
                    } label: {
                        Text("spendingMap.editor.cancel", bundle: .module)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveButtonTapped)
                    } label: {
                        Text("spendingMap.editor.save", bundle: .module)
                    }
                }
            }
        }
    }
}

struct SpendingMapDraftPicker: View {
    @Binding var latitude: Double
    @Binding var longitude: Double
    @Binding var cameraPosition: MapCameraPosition

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Map(position: $cameraPosition) {
                Marker("", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    .tint(Color.kaso.accent)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .onMapCameraChange(frequency: .onEnd) { context in
                latitude = context.camera.centerCoordinate.latitude
                longitude = context.camera.centerCoordinate.longitude
            }

            HStack {
                Text("(\(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude)))")
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
            }
        }
    }
}
