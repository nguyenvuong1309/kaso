import ComposableArchitecture
import Foundation
import LegacyDomain

#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

public struct BiometricAuthClient: Sendable {
    public var authenticate: @Sendable (_ reason: String) async -> Bool

    public init(authenticate: @escaping @Sendable (_ reason: String) async -> Bool) {
        self.authenticate = authenticate
    }
}

public struct LegacyExportFileClient: Sendable {
    public var export: @Sendable (
        _ vault: LegacyVault,
        _ password: String,
        _ encryptionHint: String
    ) async throws -> URL

    public init(
        export: @escaping @Sendable (
            _ vault: LegacyVault,
            _ password: String,
            _ encryptionHint: String
        ) async throws -> URL
    ) {
        self.export = export
    }
}

public extension BiometricAuthClient {
    static let empty = BiometricAuthClient(authenticate: { _ in true })
    static let preview = empty

    static var live: BiometricAuthClient {
        #if canImport(LocalAuthentication)
        BiometricAuthClient { reason in
            await withCheckedContinuation { continuation in
                let context = LAContext()
                var error: NSError?
                let policy: LAPolicy = .deviceOwnerAuthentication
                guard context.canEvaluatePolicy(policy, error: &error) else {
                    continuation.resume(returning: false)
                    return
                }
                context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                    continuation.resume(returning: success)
                }
            }
        }
        #else
        .empty
        #endif
    }
}

public extension LegacyExportFileClient {
    static let empty = LegacyExportFileClient(
        export: { _, _, _ in
            FileManager.default.temporaryDirectory
                .appendingPathComponent("kaso-empty.kasovault", isDirectory: false)
        }
    )

    static let live = LegacyExportFileClient { vault, password, encryptionHint in
        let package = try LegacyVaultExporter().export(
            vault: vault,
            password: password,
            encryptionHint: encryptionHint
        )
        let data = try JSONEncoder().encode(package)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kaso-legacy-\(package.exportedAt.timeIntervalSince1970).kasovault")
        try data.write(to: url, options: [.atomic])
        return url
    }
}

private enum LegacyVaultRepositoryKey: DependencyKey {
    static let liveValue = LegacyVaultRepository.empty
    static let previewValue = LegacyVaultRepository.preview
    static let testValue = LegacyVaultRepository.empty
}

private enum BiometricAuthClientKey: DependencyKey {
    static let liveValue = BiometricAuthClient.empty
    static let previewValue = BiometricAuthClient.preview
    static let testValue = BiometricAuthClient.empty
}

private enum LegacyExportFileClientKey: DependencyKey {
    static let liveValue = LegacyExportFileClient.empty
    static let previewValue = LegacyExportFileClient.empty
    static let testValue = LegacyExportFileClient.empty
}

public extension LegacyVaultRepository {
    static let preview = LegacyVaultRepository(
        load: { .preview },
        save: { _ in }
    )
}

public extension DependencyValues {
    var legacyVaultRepository: LegacyVaultRepository {
        get { self[LegacyVaultRepositoryKey.self] }
        set { self[LegacyVaultRepositoryKey.self] = newValue }
    }

    var biometricAuthClient: BiometricAuthClient {
        get { self[BiometricAuthClientKey.self] }
        set { self[BiometricAuthClientKey.self] = newValue }
    }

    var legacyExportFileClient: LegacyExportFileClient {
        get { self[LegacyExportFileClientKey.self] }
        set { self[LegacyExportFileClientKey.self] = newValue }
    }
}
