import CloudSyncDomain
import ComposableArchitecture
import KasoDesignSystem
import SwiftUI

public struct CloudSyncView: View {
    @Bindable private var store: StoreOf<CloudSyncFeature>

    public init(store: StoreOf<CloudSyncFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                KasoCard {
                    headerCard
                }

                KasoCard {
                    toggleCard
                }

                if store.preferences.isEnabled {
                    KasoCard {
                        syncCard
                    }
                }

                KasoCard {
                    privacyCard
                }

                if let messageKey = store.errorMessageKey {
                    Label {
                        Text(LocalizedStringKey(messageKey), bundle: .module)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.destructive)
                    .padding(Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Color.kaso.destructive.opacity(0.12))
                    )
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
        .task {
            await store.send(.task).finish()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("cloudSync.header.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)
            Text("cloudSync.header.subtitle", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var toggleCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Toggle(isOn: Binding(
                get: { store.preferences.isEnabled },
                set: { store.send(.toggleEnabled($0)) }
            )) {
                Text("cloudSync.toggle.label", bundle: .module)
                    .font(.kaso.body.weight(.semibold))
            }
            .disabled(store.status.availability != .available)

            Text(LocalizedStringKey(availabilityKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var syncCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Label {
                    Text(LocalizedStringKey(store.status.statusKey), bundle: .module)
                        .font(.kaso.body.weight(.semibold))
                } icon: {
                    Image(systemName: statusIcon)
                        .foregroundStyle(statusTint)
                }
                Spacer()
            }

            if case let .idle(lastDate) = store.status.state, let lastDate {
                Text(lastDate, format: .relative(presentation: .named))
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            Button {
                store.send(.syncNowButtonTapped)
            } label: {
                Label {
                    Text("cloudSync.action.syncNow", bundle: .module)
                } icon: {
                    if case .syncing = store.status.state {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(syncDisabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text("cloudSync.privacy.title", bundle: .module)
                    .font(.kaso.body.weight(.semibold))
            } icon: {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(Color.kaso.accent)
            }
            Text("cloudSync.privacy.body", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var availabilityKey: String {
        switch store.status.availability {
        case .available: "cloudSync.availability.available"
        case .unavailable: "cloudSync.availability.unavailable"
        case .restricted: "cloudSync.availability.restricted"
        case .temporarilyUnavailable: "cloudSync.availability.temporary"
        }
    }

    private var statusIcon: String {
        switch store.status.state {
        case .disabled: "icloud.slash"
        case .idle: "checkmark.icloud"
        case .syncing: "icloud.and.arrow.up.fill"
        case .failed: "exclamationmark.icloud.fill"
        }
    }

    private var statusTint: Color {
        switch store.status.state {
        case .disabled: Color.kaso.textSecondary
        case .idle: Color.kaso.accent
        case .syncing: Color.kaso.accent
        case .failed: Color.kaso.destructive
        }
    }

    private var syncDisabled: Bool {
        if case .syncing = store.status.state { return true }
        return store.status.availability != .available
    }
}
