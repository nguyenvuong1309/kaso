import Foundation
import OnboardingDomain
import Security

public enum KeychainOnboardingProfileStoreError: Error, Equatable, Sendable {
    case invalidData
    case unhandledStatus(OSStatus)
}

public actor KeychainOnboardingProfileStore {
    private let service: String
    private let account: String

    public init(
        service: String = "vn.kaso.onboarding",
        account: String = "onboarding-profile"
    ) {
        self.service = service
        self.account = account
    }

    public func load() throws -> OnboardingProfile? {
        let query = baseQuery()
        query[kSecReturnData] = kCFBooleanTrue
        query[kSecMatchLimit] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query, &item)
        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeychainOnboardingProfileStoreError.unhandledStatus(status)
        }

        guard let data = item as? Data else {
            throw KeychainOnboardingProfileStoreError.invalidData
        }

        return try JSONDecoder().decode(OnboardingProfile.self, from: data)
    }

    public func save(_ profile: OnboardingProfile) throws {
        let data = try JSONEncoder().encode(profile)
        let query = baseQuery()
        SecItemDelete(query)

        query[kSecValueData] = data as NSData
        query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query, nil)
        guard status == errSecSuccess else {
            throw KeychainOnboardingProfileStoreError.unhandledStatus(status)
        }
    }

    public func clear() throws {
        let status = SecItemDelete(baseQuery())
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainOnboardingProfileStoreError.unhandledStatus(status)
        }
    }

    public nonisolated func repository() -> OnboardingProfileRepository {
        OnboardingProfileRepository(
            load: {
                try await self.load()
            },
            save: { profile in
                try await self.save(profile)
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
