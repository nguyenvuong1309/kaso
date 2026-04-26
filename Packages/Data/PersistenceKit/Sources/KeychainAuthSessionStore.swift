import AuthDomain
import Foundation
import Security

public enum KeychainAuthSessionStoreError: Error, Equatable, Sendable {
    case invalidData
    case unhandledStatus(OSStatus)
}

public actor KeychainAuthSessionStore {
    private let service: String
    private let account: String

    public init(
        service: String = "com.vuongnguyen.kaso.auth",
        account: String = "auth-session"
    ) {
        self.service = service
        self.account = account
    }

    public func load() throws -> AuthSession? {
        let query = baseQuery()
        query[kSecReturnData] = kCFBooleanTrue
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainAuthSessionStoreError.unhandledStatus(status)
        }

        guard let data = item as? Data else {
            throw KeychainAuthSessionStoreError.invalidData
        }

        return try JSONDecoder().decode(AuthSession.self, from: data)
    }

    public func save(_ session: AuthSession) throws {
        let data = try JSONEncoder().encode(session)
        let query = baseQuery()
        SecItemDelete(query)

        query[kSecValueData] = data as NSData
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            throw KeychainAuthSessionStoreError.unhandledStatus(status)
        }
    }

    public func clear() throws {
        let status = SecItemDelete(baseQuery())
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainAuthSessionStoreError.unhandledStatus(status)
        }
    }

    public nonisolated func repository() -> AuthSessionRepository {
        AuthSessionRepository(
            load: {
                try await self.load()
            },
            save: { session in
                try await self.save(session)
            },
            clear: {
                try await self.clear()
            }
        )
    }

    private func baseQuery() -> NSMutableDictionary {
        let query = NSMutableDictionary()
        query[kSecClass] = kSecClassGenericPassword
        query[kSecAttrService] = service as NSString
        query[kSecAttrAccount] = account as NSString
        return query
    }
}
