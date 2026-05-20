import Foundation

public struct SmartSearchQuery: Equatable, Sendable {
    public let rawText: String
    public let keyword: String
    public let dateRange: DateInterval?

    public init(rawText: String, keyword: String, dateRange: DateInterval?) {
        self.rawText = rawText
        self.keyword = keyword
        self.dateRange = dateRange
    }

    public var hasDateRange: Bool { dateRange != nil }
}
