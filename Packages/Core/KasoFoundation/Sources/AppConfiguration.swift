import Foundation

/// The build environment the app was compiled for.
public enum KasoEnvironment: String, Sendable {
    case dev
    case prod
}

/// Per-environment configuration resolved at launch from the target's
/// `Info.plist`. The values originate from `Config/Dev.xcconfig` /
/// `Config/Prod.xcconfig` and are injected via `$(VAR)` substitution.
///
/// Defaults are deliberately the *prod* values so that any context without a
/// configured Info.plist (unit tests, previews) behaves like production: no
/// verbose logging, no PII exposure.
public struct AppConfiguration: Sendable {
    public let environment: KasoEnvironment
    public let apiBaseURL: URL?
    public let appGroupIdentifier: String
    public let isVerboseLoggingEnabled: Bool

    public static let current = AppConfiguration(bundle: .main)

    public init(bundle: Bundle) {
        let info = bundle.infoDictionary ?? [:]

        let rawEnvironment = info["KasoEnvironment"] as? String
        environment = rawEnvironment.flatMap(KasoEnvironment.init(rawValue:)) ?? .prod

        if let urlString = info["KasoAPIBaseURL"] as? String, !urlString.isEmpty {
            apiBaseURL = URL(string: urlString)
        } else {
            apiBaseURL = nil
        }

        appGroupIdentifier = (info["KasoAppGroupIdentifier"] as? String)
            ?? "group.com.vuongnguyen.kaso"
        isVerboseLoggingEnabled = (info["KasoVerboseLogging"] as? String) == "YES"
    }
}
