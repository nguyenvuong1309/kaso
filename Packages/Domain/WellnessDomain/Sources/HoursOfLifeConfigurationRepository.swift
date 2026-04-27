import Foundation

public struct HoursOfLifeConfigurationRepository: Sendable {
    public var load: @Sendable () async throws -> HoursOfLifeConfiguration?
    public var save: @Sendable (HoursOfLifeConfiguration) async throws -> Void
    public var clear: @Sendable () async throws -> Void

    public init(
        load: @escaping @Sendable () async throws -> HoursOfLifeConfiguration?,
        save: @escaping @Sendable (HoursOfLifeConfiguration) async throws -> Void,
        clear: @escaping @Sendable () async throws -> Void
    ) {
        self.load = load
        self.save = save
        self.clear = clear
    }
}

public extension HoursOfLifeConfigurationRepository {
    static let empty = HoursOfLifeConfigurationRepository(
        load: { nil },
        save: { _ in },
        clear: {}
    )
}
