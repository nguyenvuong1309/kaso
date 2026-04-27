import Foundation

public enum FreelancerWorkType: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case freelancer
    case gigDriver
    case onlineSeller
    case other

    public var id: String { rawValue }

    public var titleKey: String {
        "freelancer.workType.\(rawValue)"
    }
}

public enum SmoothingWindow: Int, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case threeMonths = 3
    case sixMonths = 6
    case twelveMonths = 12

    public var id: Int { rawValue }

    public var titleKey: String {
        switch self {
        case .threeMonths:
            "freelancer.window.three"
        case .sixMonths:
            "freelancer.window.six"
        case .twelveMonths:
            "freelancer.window.twelve"
        }
    }
}

public enum IncomeDeductionCategory: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case tax
    case businessCost
    case insurance
    case platformFee
    case other

    public var id: String { rawValue }
}

public struct IncomeDeduction: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var amount: Decimal
    public var category: IncomeDeductionCategory

    public init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        category: IncomeDeductionCategory
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
    }
}

public struct MonthlyIncome: Identifiable, Codable, Equatable, Sendable {
    public var month: YearMonth
    public var grossAmount: Decimal
    public var deductions: [IncomeDeduction]

    public var id: YearMonth { month }

    public var netAmount: Decimal {
        max(0, grossAmount - deductions.reduce(Decimal(0)) { $0 + max(0, $1.amount) })
    }

    public init(
        month: YearMonth,
        grossAmount: Decimal,
        deductions: [IncomeDeduction] = []
    ) {
        self.month = month
        self.grossAmount = grossAmount
        self.deductions = deductions
    }
}

public struct FreelancerProfile: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var monthlyIncomes: [MonthlyIncome]
    public var smoothingWindow: SmoothingWindow
    public var bufferBalance: Decimal
    public var bufferTargetMultiplier: Double
    public var workType: FreelancerWorkType
    public var taxRate: Double?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        monthlyIncomes: [MonthlyIncome] = [],
        smoothingWindow: SmoothingWindow = .threeMonths,
        bufferBalance: Decimal = 0,
        bufferTargetMultiplier: Double = 2,
        workType: FreelancerWorkType = .freelancer,
        taxRate: Double? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.monthlyIncomes = monthlyIncomes
        self.smoothingWindow = smoothingWindow
        self.bufferBalance = bufferBalance
        self.bufferTargetMultiplier = bufferTargetMultiplier
        self.workType = workType
        self.taxRate = taxRate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum FreelancerBufferStatus: String, Codable, Equatable, Sendable {
    case danger
    case warning
    case healthy
}

public struct FreelancerSmoothedView: Codable, Equatable, Sendable {
    public let smoothedMonthlyIncome: Decimal
    public let currentMonthNetIncome: Decimal
    public let bufferBalance: Decimal
    public let bufferTarget: Decimal
    public let bufferCoverage: Double
    public let currentMonthSurplus: Decimal
    public let currentMonthDeficit: Decimal
    public let taxProvision: Decimal
    public let window: SmoothingWindow
    public let bufferStatus: FreelancerBufferStatus

    public init(
        smoothedMonthlyIncome: Decimal,
        currentMonthNetIncome: Decimal,
        bufferBalance: Decimal,
        bufferTarget: Decimal,
        bufferCoverage: Double,
        currentMonthSurplus: Decimal,
        currentMonthDeficit: Decimal,
        taxProvision: Decimal,
        window: SmoothingWindow,
        bufferStatus: FreelancerBufferStatus
    ) {
        self.smoothedMonthlyIncome = smoothedMonthlyIncome
        self.currentMonthNetIncome = currentMonthNetIncome
        self.bufferBalance = bufferBalance
        self.bufferTarget = bufferTarget
        self.bufferCoverage = bufferCoverage
        self.currentMonthSurplus = currentMonthSurplus
        self.currentMonthDeficit = currentMonthDeficit
        self.taxProvision = taxProvision
        self.window = window
        self.bufferStatus = bufferStatus
    }
}

public enum FreelancerReminder: Codable, Equatable, Identifiable, Sendable {
    case taxDeadline(amount: Decimal, dueDate: Date)
    case insuranceRenewal(provider: String, dueDate: Date)
    case lowBuffer(monthsCovered: Double)
    case slowSeasonAlert(historicalPattern: String)

    public var id: String {
        switch self {
        case let .taxDeadline(amount, dueDate):
            "tax-\(amount)-\(dueDate.timeIntervalSinceReferenceDate)"
        case let .insuranceRenewal(provider, dueDate):
            "insurance-\(provider)-\(dueDate.timeIntervalSinceReferenceDate)"
        case let .lowBuffer(monthsCovered):
            "buffer-\(monthsCovered)"
        case let .slowSeasonAlert(pattern):
            "slow-\(pattern)"
        }
    }
}
