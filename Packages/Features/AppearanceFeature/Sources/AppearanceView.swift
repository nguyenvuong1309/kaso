import AppearanceDomain
import ComposableArchitecture
import KasoDesignSystem
import SwiftUI

public struct AppearanceRootView: View {
    private let store: StoreOf<AppearanceFeature>

    public init(repository: AppearanceSettingsRepository = .empty) {
        store = Store(initialState: AppearanceFeature.State()) {
            AppearanceFeature()
        } withDependencies: {
            $0.appearanceSettingsRepository = repository
        }
    }

    public var body: some View {
        AppearanceView(store: store)
            .task {
                await store.send(.task).finish()
            }
    }
}

public struct AppearanceView: View {
    @Bindable private var store: StoreOf<AppearanceFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<AppearanceFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    headerSection
                    modeSection
                    accentSection

                    if let errorMessageKey = store.errorMessageKey {
                        Text(LocalizedStringKey(errorMessageKey), bundle: .module)
                            .font(.kaso.caption)
                            .foregroundStyle(Color.kaso.destructive)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("appearance.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.settingsDismissed)
                        dismiss()
                    } label: {
                        Text("appearance.done", bundle: .module)
                    }
                }
            }
            .overlay {
                if store.isSaving {
                    ProgressView()
                        .padding(Spacing.md)
                        .background(
                            Color.kaso.surfaceSecondary,
                            in: RoundedRectangle(
                                cornerRadius: Radius.lg,
                                style: .continuous
                            )
                        )
                        .accessibilityLabel(Text("appearance.saving", bundle: .module))
                }
            }
        }
    }

    private var headerSection: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("appearance.header.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)

                Text("appearance.header.subtitle", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var modeSection: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                sectionTitle("appearance.mode.title")

                Picker(
                    selection: modeBinding,
                    label: Text("appearance.mode.title", bundle: .module)
                ) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(LocalizedStringKey(mode.titleKey), bundle: .module)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var accentSection: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                sectionTitle("appearance.accent.title")

                LazyVGrid(columns: Layout.optionColumns, spacing: Spacing.sm) {
                    ForEach(AccentColorOption.allCases) { accentColor in
                        AccentColorButton(
                            accentColor: accentColor,
                            isSelected: store.settings.accentColor == accentColor,
                            action: {
                                store.send(.accentColorSelected(accentColor))
                            }
                        )
                    }
                }
            }
        }
    }

    private var modeBinding: Binding<AppearanceMode> {
        Binding(
            get: { store.settings.mode },
            set: { store.send(.modeSelected($0)) }
        )
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(LocalizedStringKey(key), bundle: .module)
            .font(.kaso.titleMedium)
            .foregroundStyle(Color.kaso.textPrimary)
    }
}

private struct AccentColorButton: View {
    let accentColor: AccentColorOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.sm) {
                Circle()
                    .fill(accentColor.color)
                    .frame(width: Spacing.xl, height: Spacing.xl)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.kaso.caption)
                                .foregroundStyle(.white)
                        }
                    }

                Text(LocalizedStringKey(accentColor.titleKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .fill(Color.kaso.surfacePrimary)
            )
            .overlay {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.kaso.accent : Color.kaso.textSecondary.opacity(0.2),
                        lineWidth: isSelected ? Layout.selectedBorderWidth : Layout.borderWidth
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private enum Layout {
    static let optionColumns = [
        GridItem(.adaptive(minimum: Spacing.xl * 3), spacing: Spacing.sm),
    ]
    static let borderWidth: CGFloat = 1
    static let selectedBorderWidth: CGFloat = 2
}

public extension AppearanceMode {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

public extension AccentColorOption {
    var color: Color {
        Color.kaso.accent(named: rawValue)
    }
}

private extension AppearanceMode {
    var titleKey: String {
        switch self {
        case .system:
            "appearance.mode.system"
        case .light:
            "appearance.mode.light"
        case .dark:
            "appearance.mode.dark"
        }
    }
}

private extension AccentColorOption {
    var titleKey: String {
        "appearance.accent.\(rawValue)"
    }
}

#Preview("Light") {
    AppearanceView(
        store: Store(
            initialState: AppearanceFeature.State()
        ) {
            AppearanceFeature()
        }
    )
}

#Preview("Dark") {
    AppearanceView(
        store: Store(
            initialState: AppearanceFeature.State(
                settings: AppearanceSettings(mode: .dark, accentColor: .purple)
            )
        ) {
            AppearanceFeature()
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    AppearanceView(
        store: Store(
            initialState: AppearanceFeature.State()
        ) {
            AppearanceFeature()
        }
    )
    .environment(\.dynamicTypeSize, .accessibility1)
}
