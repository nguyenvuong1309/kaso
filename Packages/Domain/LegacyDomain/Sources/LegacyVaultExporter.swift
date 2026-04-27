import CryptoKit
import Foundation
import Security

public enum LegacyVaultExporterError: Error, Equatable, Sendable {
    case emptyPassword
    case invalidPassword
    case invalidPackage
}

public struct LegacyExportPackage: Codable, Equatable, Sendable {
    public let vaultData: Data
    public let salt: Data
    public let encryptionHint: String
    public let exportedAt: Date
    public let version: Int

    public init(
        vaultData: Data,
        salt: Data,
        encryptionHint: String,
        exportedAt: Date,
        version: Int = 1
    ) {
        self.vaultData = vaultData
        self.salt = salt
        self.encryptionHint = encryptionHint
        self.exportedAt = exportedAt
        self.version = version
    }
}

public struct LegacyVaultExporter: Sendable {
    public typealias SaltGenerator = @Sendable () throws -> Data
    public typealias DateProvider = @Sendable () -> Date

    private let saltGenerator: SaltGenerator
    private let dateProvider: DateProvider
    private let iterationCount: Int

    public init(
        saltGenerator: @escaping SaltGenerator = {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            guard status == errSecSuccess else {
                throw LegacyVaultExporterError.invalidPackage
            }
            return Data(bytes)
        },
        dateProvider: @escaping DateProvider = { Date() },
        iterationCount: Int = 100_000
    ) {
        self.saltGenerator = saltGenerator
        self.dateProvider = dateProvider
        self.iterationCount = iterationCount
    }

    public func export(
        vault: LegacyVault,
        password: String,
        encryptionHint: String
    ) throws -> LegacyExportPackage {
        guard password.isEmpty == false else {
            throw LegacyVaultExporterError.emptyPassword
        }

        let salt = try saltGenerator()
        let key = try PasswordKeyDeriver.deriveKey(
            password: password,
            salt: salt,
            iterations: iterationCount
        )
        let vaultData = try JSONEncoder().encode(vault)
        let sealedBox = try AES.GCM.seal(vaultData, using: key)
        guard let encryptedData = sealedBox.combined else {
            throw LegacyVaultExporterError.invalidPackage
        }

        return LegacyExportPackage(
            vaultData: encryptedData,
            salt: salt,
            encryptionHint: encryptionHint,
            exportedAt: dateProvider()
        )
    }

    public func decrypt(
        package: LegacyExportPackage,
        password: String
    ) throws -> LegacyVault {
        guard password.isEmpty == false else {
            throw LegacyVaultExporterError.emptyPassword
        }

        let key = try PasswordKeyDeriver.deriveKey(
            password: password,
            salt: package.salt,
            iterations: iterationCount
        )

        do {
            let sealedBox = try AES.GCM.SealedBox(combined: package.vaultData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return try JSONDecoder().decode(LegacyVault.self, from: decryptedData)
        } catch {
            throw LegacyVaultExporterError.invalidPassword
        }
    }
}

private enum PasswordKeyDeriver {
    static func deriveKey(
        password: String,
        salt: Data,
        iterations: Int,
        outputByteCount: Int = 32
    ) throws -> SymmetricKey {
        guard let passwordData = password.data(using: .utf8), passwordData.isEmpty == false else {
            throw LegacyVaultExporterError.emptyPassword
        }

        let bytes = pbkdf2SHA256(
            passwordData: passwordData,
            salt: salt,
            iterations: max(1, iterations),
            outputByteCount: outputByteCount
        )
        return SymmetricKey(data: Data(bytes))
    }

    static func pbkdf2SHA256(
        passwordData: Data,
        salt: Data,
        iterations: Int,
        outputByteCount: Int
    ) -> [UInt8] {
        let hashByteCount = 32
        let blockCount = Int(ceil(Double(outputByteCount) / Double(hashByteCount)))
        let passwordKey = SymmetricKey(data: passwordData)
        var derivedBytes: [UInt8] = []

        for blockIndex in 1...blockCount {
            var blockSalt = Data(salt)
            blockSalt.append(contentsOf: int32BigEndian(blockIndex))
            var u = hmac(data: blockSalt, key: passwordKey)
            var t = u

            if iterations > 1 {
                for _ in 2...iterations {
                    u = hmac(data: Data(u), key: passwordKey)
                    for index in t.indices {
                        t[index] ^= u[index]
                    }
                }
            }

            derivedBytes.append(contentsOf: t)
        }

        return Array(derivedBytes.prefix(outputByteCount))
    }

    static func hmac(data: Data, key: SymmetricKey) -> [UInt8] {
        Array(HMAC<SHA256>.authenticationCode(for: data, using: key))
    }

    static func int32BigEndian(_ value: Int) -> [UInt8] {
        [
            UInt8((value >> 24) & 0xff),
            UInt8((value >> 16) & 0xff),
            UInt8((value >> 8) & 0xff),
            UInt8(value & 0xff),
        ]
    }
}
