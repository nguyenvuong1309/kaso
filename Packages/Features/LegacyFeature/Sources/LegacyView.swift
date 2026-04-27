import SwiftUI
import ComposableArchitecture
import KasoDesignSystem
import LegacyDomain

public struct LegacyRootView: View {
    private let store: StoreOf<LegacyFeature>

    public init(
        repository: LegacyVaultRepository = .empty,
        biometricAuthClient: BiometricAuthClient = .empty,
        exportFileClient: LegacyExportFileClient = .empty
    ) {
        store = Store(initialState: LegacyFeature.State()) {
            LegacyFeature()
        } withDependencies: {
            $0.legacyVaultRepository = repository
            $0.biometricAuthClient = biometricAuthClient
            $0.legacyExportFileClient = exportFileClient
        }
    }

    public var body: some View {
        LegacyView(store: store)
    }
}

public struct LegacyView: View {
    @Bindable private var store: StoreOf<LegacyFeature>

    public init(store: StoreOf<LegacyFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
                if store.isLocked {
                    LegacyLockedView(
                        authenticationState: store.authenticationState,
                        errorMessageKey: store.errorMessageKey,
                        onUnlock: {
                            store.send(.authenticateButtonTapped)
                        }
                    )
                } else {
                    LegacyDashboardView(store: store)
                }
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("legacy.title", bundle: .module))
            .toolbar {
                if store.isLocked == false {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            store.send(.lock)
                        } label: {
                            Image(systemName: "lock")
                        }
                        .accessibilityLabel(Text("legacy.lock", bundle: .module))
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            store.send(.exportButtonTapped)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel(Text("legacy.export", bundle: .module))
                    }
                }
            }
            .sheet(isPresented: accountEditorPresented) {
                LegacyAccountEditorSheet(store: store)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: exportSheetPresented) {
                LegacyExportSheet(store: store)
                    .presentationDetents([.medium])
            }
        }
    }

    private var accountEditorPresented: Binding<Bool> {
        Binding(
            get: { store.isAccountEditorPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.accountEditorDismissed)
                }
            }
        )
    }

    private var exportSheetPresented: Binding<Bool> {
        Binding(
            get: { store.isExportSheetPresented },
            set: { isPresented in
                if isPresented == false {
                    store.send(.exportSheetDismissed)
                }
            }
        )
    }
}

private struct LegacyLockedView: View {
    let authenticationState: LegacyFeature.AuthenticationState
    let errorMessageKey: String?
    let onUnlock: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "lock.shield")
                .font(.system(size: Layout.lockIconSize))
                .foregroundStyle(Color.kaso.accent)
                .scaleEffect(reduceMotion ? 1 : Layout.lockScale)
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 1).repeatForever(autoreverses: true),
                    value: reduceMotion
                )

            Text("legacy.locked.title", bundle: .module)
                .font(.kaso.titleLarge)

            Text("legacy.locked.body", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)

            if authenticationState == .authenticating {
                ProgressView()
            }

            if let errorMessageKey {
                Text(LocalizedStringKey(errorMessageKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.destructive)
            }

            Button {
                onUnlock()
            } label: {
                Text("legacy.unlock", bundle: .module)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(authenticationState == .authenticating)
        }
        .padding(Spacing.lg)
    }
}

private enum Layout {
    static let lockIconSize: CGFloat = 56
    static let lockScale: CGFloat = 1.05
}
