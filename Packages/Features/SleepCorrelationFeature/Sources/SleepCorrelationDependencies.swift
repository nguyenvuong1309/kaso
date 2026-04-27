import ComposableArchitecture
import Foundation
import SleepCorrelationDomain

#if canImport(HealthKit)
import HealthKit
#endif

public enum HealthAuthorizationStatus: String, Equatable, Sendable {
    case notDetermined
    case sharingDenied
    case sharingAuthorized
}

public struct HealthSleepClient: Sendable {
    public var authorizationStatus: @Sendable () async -> HealthAuthorizationStatus
    public var requestAuthorization: @Sendable () async throws -> Bool
    public var sleepSamples: @Sendable () async throws -> [SleepSample]

    public init(
        authorizationStatus: @escaping @Sendable () async -> HealthAuthorizationStatus,
        requestAuthorization: @escaping @Sendable () async throws -> Bool,
        sleepSamples: @escaping @Sendable () async throws -> [SleepSample]
    ) {
        self.authorizationStatus = authorizationStatus
        self.requestAuthorization = requestAuthorization
        self.sleepSamples = sleepSamples
    }
}

public struct SleepCorrelationDataClient: Sendable {
    public var loadDataPoints: @Sendable () async throws -> [SleepSpendingDataPoint]

    public init(
        loadDataPoints: @escaping @Sendable () async throws -> [SleepSpendingDataPoint]
    ) {
        self.loadDataPoints = loadDataPoints
    }
}

public extension HealthSleepClient {
    static let empty = HealthSleepClient(
        authorizationStatus: { .notDetermined },
        requestAuthorization: { false },
        sleepSamples: { [] }
    )

    static let preview = HealthSleepClient(
        authorizationStatus: { .sharingAuthorized },
        requestAuthorization: { true },
        sleepSamples: {
            (0..<30).map { index in
                SleepSample(
                    date: Date(timeIntervalSinceReferenceDate: Double(index) * 86_400),
                    hours: 5.5 + Double(index % 5) * 0.4
                )
            }
        }
    )

    static var live: HealthSleepClient {
        #if canImport(HealthKit)
        HealthSleepClient(
            authorizationStatus: {
                guard
                    HKHealthStore.isHealthDataAvailable(),
                    let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
                else {
                    return .sharingDenied
                }

                switch HKHealthStore().authorizationStatus(for: sleepType) {
                case .notDetermined:
                    return .notDetermined
                case .sharingDenied:
                    return .sharingDenied
                case .sharingAuthorized:
                    return .sharingAuthorized
                @unknown default:
                    return .sharingDenied
                }
            },
            requestAuthorization: {
                try await HealthKitSleepReader.requestAuthorization()
            },
            sleepSamples: {
                try await HealthKitSleepReader.sleepSamples()
            }
        )
        #else
        .empty
        #endif
    }
}

public extension SleepCorrelationDataClient {
    static let empty = SleepCorrelationDataClient(loadDataPoints: { [] })

    static let preview = SleepCorrelationDataClient(
        loadDataPoints: {
            (0..<30).map { index in
                SleepSpendingDataPoint(
                    date: Date(timeIntervalSinceReferenceDate: Double(index) * 86_400),
                    sleepHours: 5 + Double(index % 5) * 0.5,
                    totalSpending: Decimal(420_000 - index * 7_000),
                    transactionCount: max(1, index % 5),
                    categories: []
                )
            }
        }
    )
}

private enum HealthSleepClientKey: DependencyKey {
    static let liveValue = HealthSleepClient.empty
    static let previewValue = HealthSleepClient.preview
    static let testValue = HealthSleepClient.empty
}

private enum SleepCorrelationDataClientKey: DependencyKey {
    static let liveValue = SleepCorrelationDataClient.empty
    static let previewValue = SleepCorrelationDataClient.preview
    static let testValue = SleepCorrelationDataClient.empty
}

public extension DependencyValues {
    var healthSleepClient: HealthSleepClient {
        get { self[HealthSleepClientKey.self] }
        set { self[HealthSleepClientKey.self] = newValue }
    }

    var sleepCorrelationDataClient: SleepCorrelationDataClient {
        get { self[SleepCorrelationDataClientKey.self] }
        set { self[SleepCorrelationDataClientKey.self] = newValue }
    }
}

#if canImport(HealthKit)
private enum HealthKitSleepReader {
    enum ReaderError: Error {
        case unavailable
    }

    static func requestAuthorization() async throws -> Bool {
        guard
            HKHealthStore.isHealthDataAvailable(),
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        else {
            return false
        }

        return try await withCheckedThrowingContinuation { continuation in
            HKHealthStore().requestAuthorization(toShare: [], read: [sleepType]) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    static func sleepSamples() async throws -> [SleepSample] {
        guard
            HKHealthStore.isHealthDataAvailable(),
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        else {
            return []
        }

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate) ?? endDate
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate]
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let categorySamples = samples?.compactMap { $0 as? HKCategorySample } ?? []
                continuation.resume(returning: aggregate(categorySamples))
            }

            HKHealthStore().execute(query)
        }
    }

    private static func aggregate(_ samples: [HKCategorySample]) -> [SleepSample] {
        let calendar = Calendar.current
        let asleepDurations = samples.reduce(into: [Date: TimeInterval]()) { result, sample in
            guard isAsleep(sample) else {
                return
            }
            let day = calendar.startOfDay(for: sample.startDate)
            result[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate)
        }

        return asleepDurations
            .map { SleepSample(date: $0.key, hours: $0.value / 3_600) }
            .sorted { $0.date < $1.date }
    }

    private static func isAsleep(_ sample: HKCategorySample) -> Bool {
        sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue
            && sample.value != HKCategoryValueSleepAnalysis.awake.rawValue
    }
}
#endif
