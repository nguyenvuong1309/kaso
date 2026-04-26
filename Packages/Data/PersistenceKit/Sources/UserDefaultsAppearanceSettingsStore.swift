import AppearanceDomain
import Foundation

public actor UserDefaultsAppearanceSettingsStore {
    private let defaults: UserDefaults
    private let key: String

    public init(
        suiteName: String? = nil,
        key: String = "kaso.appearance.settings"
    ) {
        if let suiteName, let defaults = UserDefaults(suiteName: suiteName) {
            self.defaults = defaults
        } else {
            self.defaults = .standard
        }
        self.key = key
    }

    public nonisolated func repository() -> AppearanceSettingsRepository {
        AppearanceSettingsRepository(
            load: { try await self.load() },
            save: { try await self.save($0) }
        )
    }

    private func load() throws -> AppearanceSettings {
        guard let data = defaults.data(forKey: key) else {
            return .defaultValue
        }

        do {
            return try JSONDecoder().decode(AppearanceSettings.self, from: data)
        } catch {
            defaults.removeObject(forKey: key)
            return .defaultValue
        }
    }

    private func save(_ settings: AppearanceSettings) throws {
        let data = try JSONEncoder().encode(settings)
        defaults.set(data, forKey: key)
    }
}
