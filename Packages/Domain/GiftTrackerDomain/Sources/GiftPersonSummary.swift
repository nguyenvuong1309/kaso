import Foundation

public struct GiftPersonSummary: Identifiable, Equatable, Sendable {
    public let personName: String
    public var totalGiven: Decimal
    public var totalReceived: Decimal
    public var lastEventDate: Date
    public var lastEventKind: GiftEventKind
    public var records: [GiftRecord]

    public var id: String { personName }

    public var netBalance: Decimal { totalReceived - totalGiven }

    public var suggestedAmount: Decimal {
        guard records.isEmpty == false else { return 0 }
        let given = records.filter { $0.direction == .given }
        guard given.isEmpty == false else {
            return records.map(\.amount).reduce(0, +) / Decimal(records.count)
        }
        return given.map(\.amount).reduce(0, +) / Decimal(given.count)
    }

    public init(
        personName: String,
        totalGiven: Decimal,
        totalReceived: Decimal,
        lastEventDate: Date,
        lastEventKind: GiftEventKind,
        records: [GiftRecord]
    ) {
        self.personName = personName
        self.totalGiven = totalGiven
        self.totalReceived = totalReceived
        self.lastEventDate = lastEventDate
        self.lastEventKind = lastEventKind
        self.records = records
    }
}

public enum GiftPersonSummaryBuilder {
    public static func build(from records: [GiftRecord]) -> [GiftPersonSummary] {
        let grouped = Dictionary(grouping: records, by: \.personName)
        return grouped.compactMap { name, personRecords -> GiftPersonSummary? in
            guard let latestRecord = personRecords.max(by: { $0.eventDate < $1.eventDate }) else {
                return nil
            }
            let given = personRecords.filter { $0.direction == .given }
            let received = personRecords.filter { $0.direction == .received }
            return GiftPersonSummary(
                personName: name,
                totalGiven: given.reduce(0) { $0 + $1.amount },
                totalReceived: received.reduce(0) { $0 + $1.amount },
                lastEventDate: latestRecord.eventDate,
                lastEventKind: latestRecord.eventKind,
                records: personRecords.sorted { $0.eventDate > $1.eventDate }
            )
        }
        .sorted { $0.lastEventDate > $1.lastEventDate }
    }
}

public struct GiftYearlySummary: Equatable, Sendable {
    public let year: Int
    public var totalGiven: Decimal
    public var totalReceived: Decimal
    public var recordCount: Int

    public var netBalance: Decimal { totalReceived - totalGiven }

    public init(year: Int, totalGiven: Decimal, totalReceived: Decimal, recordCount: Int) {
        self.year = year
        self.totalGiven = totalGiven
        self.totalReceived = totalReceived
        self.recordCount = recordCount
    }
}

public enum GiftYearlySummaryBuilder {
    public static func build(
        from records: [GiftRecord],
        calendar: Calendar = .current
    ) -> GiftYearlySummary {
        let year = calendar.component(.year, from: Date())
        let yearRecords = records.filter {
            calendar.component(.year, from: $0.eventDate) == year
        }
        let given = yearRecords.filter { $0.direction == .given }
        let received = yearRecords.filter { $0.direction == .received }
        return GiftYearlySummary(
            year: year,
            totalGiven: given.reduce(0) { $0 + $1.amount },
            totalReceived: received.reduce(0) { $0 + $1.amount },
            recordCount: yearRecords.count
        )
    }
}
