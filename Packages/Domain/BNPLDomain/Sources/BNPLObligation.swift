import Foundation

public enum BNPLProvider: String, CaseIterable, Codable, Equatable, Sendable, Identifiable {
    case fundiin
    case kredivo
    case atome
    case shopeePayLater
    case momoPostPay
    case homeCredit
    case generic

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .fundiin: "Fundiin"
        case .kredivo: "Kredivo"
        case .atome: "Atome"
        case .shopeePayLater: "Shopee PayLater"
        case .momoPostPay: "MoMo Postpaid"
        case .homeCredit: "Home Credit"
        case .generic: "Khác"
        }
    }

    public var symbolName: String {
        switch self {
        case .fundiin, .kredivo, .atome: "creditcard.fill"
        case .shopeePayLater: "bag.fill"
        case .momoPostPay: "wallet.pass.fill"
        case .homeCredit: "house.circle.fill"
        case .generic: "dollarsign.circle.fill"
        }
    }
}

public enum BNPLStatus: String, Codable, Equatable, Sendable {
    case active
    case completed
    case overdue
}

public struct BNPLInstallment: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var dueDate: Date
    public var amount: Decimal
    public var isPaid: Bool

    public init(
        id: UUID = UUID(),
        dueDate: Date,
        amount: Decimal,
        isPaid: Bool = false
    ) {
        self.id = id
        self.dueDate = dueDate
        self.amount = amount
        self.isPaid = isPaid
    }
}

public struct BNPLObligation: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var provider: BNPLProvider
    public var purchaseName: String
    public var totalAmount: Decimal
    public var purchaseDate: Date
    public var installmentCount: Int
    public var installments: [BNPLInstallment]
    public var note: String?

    public init(
        id: UUID = UUID(),
        provider: BNPLProvider,
        purchaseName: String,
        totalAmount: Decimal,
        purchaseDate: Date,
        installmentCount: Int,
        installments: [BNPLInstallment] = [],
        note: String? = nil
    ) {
        self.id = id
        self.provider = provider
        self.purchaseName = purchaseName
        self.totalAmount = totalAmount
        self.purchaseDate = purchaseDate
        self.installmentCount = installmentCount
        self.installments = installments
        self.note = note
    }

    public var remainingAmount: Decimal {
        installments
            .filter { $0.isPaid == false }
            .reduce(0) { $0 + $1.amount }
    }

    public var paidAmount: Decimal {
        installments
            .filter(\.isPaid)
            .reduce(0) { $0 + $1.amount }
    }

    public func status(at date: Date = Date()) -> BNPLStatus {
        let unpaid = installments.filter { $0.isPaid == false }
        if unpaid.isEmpty {
            return .completed
        }
        if unpaid.contains(where: { $0.dueDate < date }) {
            return .overdue
        }
        return .active
    }

    public func nextInstallment(after date: Date = Date()) -> BNPLInstallment? {
        installments
            .filter { $0.isPaid == false }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }
}

public enum BNPLInstallmentBuilder {
    public static func generateMonthly(
        totalAmount: Decimal,
        installmentCount: Int,
        startDate: Date,
        calendar: Calendar = .current
    ) -> [BNPLInstallment] {
        guard installmentCount > 0 else { return [] }
        let perInstallment = totalAmount / Decimal(installmentCount)
        return (0 ..< installmentCount).compactMap { offset in
            guard let dueDate = calendar.date(byAdding: .month, value: offset, to: startDate) else {
                return nil
            }
            return BNPLInstallment(dueDate: dueDate, amount: perInstallment)
        }
    }
}
