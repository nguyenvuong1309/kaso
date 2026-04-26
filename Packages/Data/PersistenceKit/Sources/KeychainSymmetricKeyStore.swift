import CryptoKit
import Foundation
import Security

public enum KeychainSymmetricKeyStoreError: Error, Equatable, Sendable {
    case invalidData
    case unhandledStatus(OSStatus)
}

public struct KeychainSymmetricKeyStore: Sendable {
    private let service: String
    private let account: String

    public init(
        service: String = "com.vuongnguyen.kaso.transactions",
        account: String = "transactions-encryption-key"
    ) {
        self.service = service
        self.account = account
    }

    public func loadOrCreateKeyData() throws -> Data {
        if let keyData = try loadKeyData() {
            return keyData
        }

        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        try save(keyData)
        return keyData
    }

    private func loadKeyData() throws -> Data? {
        let query = baseQuery()
        query[kSecReturnData] = kCFBooleanTrue
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainSymmetricKeyStoreError.unhandledStatus(status)
        }

        guard let data = item as? Data, data.isEmpty == false else {
            throw KeychainSymmetricKeyStoreError.invalidData
        }

        return data
    }

    private func save(_ keyData: Data) throws {
        let query = baseQuery()
        SecItemDelete(query)

        query[kSecValueData] = keyData as NSData
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            throw KeychainSymmetricKeyStoreError.unhandledStatus(status)
        }
    }

    private func baseQuery() -> NSMutableDictionary {
        let query = NSMutableDictionary()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecAttrService] = service as NSString
        query[kSecAttrAccount] = account as NSString
        return query
    }
}
