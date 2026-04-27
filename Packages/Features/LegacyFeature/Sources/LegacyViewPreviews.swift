import SwiftUI
import ComposableArchitecture
import LegacyDomain

#Preview("Light") {
    LegacyView(
        store: Store(initialState: LegacyFeature.State()) {
            LegacyFeature()
        } withDependencies: {
            $0.legacyVaultRepository = .preview
            $0.biometricAuthClient = .preview
        }
    )
}

#Preview("Dark") {
    LegacyView(
        store: Store(initialState: LegacyFeature.State(vault: .preview, isLocked: false)) {
            LegacyFeature()
        } withDependencies: {
            $0.legacyVaultRepository = .preview
            $0.biometricAuthClient = .preview
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    LegacyView(
        store: Store(initialState: LegacyFeature.State(vault: .preview, isLocked: false)) {
            LegacyFeature()
        } withDependencies: {
            $0.legacyVaultRepository = .preview
            $0.biometricAuthClient = .preview
        }
    )
    .environment(\.dynamicTypeSize, .accessibility1)
}
