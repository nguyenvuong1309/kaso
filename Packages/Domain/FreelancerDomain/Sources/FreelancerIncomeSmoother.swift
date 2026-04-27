import Foundation

public enum FreelancerIncomeSmoother {
    public static func compute(
        profile: FreelancerProfile,
        window: SmoothingWindow? = nil,
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> FreelancerSmoothedView {
        let selectedWindow = window ?? profile.smoothingWindow
        let currentMonth = YearMonth(date: date, calendar: calendar)
        let eligibleIncomes = profile.monthlyIncomes
            .filter { $0.month <= currentMonth }
            .sorted { $0.month > $1.month }
        let windowIncomes = Array(eligibleIncomes.prefix(selectedWindow.rawValue))
        let smoothedIncome = averageNetIncome(windowIncomes)
        let currentIncome = eligibleIncomes.first { $0.month == currentMonth }?.netAmount ?? 0
        let bufferTarget = smoothedIncome * decimal(profile.bufferTargetMultiplier)
        let coverage = coverageMonths(
            bufferBalance: profile.bufferBalance,
            smoothedIncome: smoothedIncome
        )
        let surplus = max(0, currentIncome - smoothedIncome)
        let deficit = max(0, smoothedIncome - currentIncome)
        let taxProvision = smoothedIncome * decimal(profile.taxRate ?? 0)

        return FreelancerSmoothedView(
            smoothedMonthlyIncome: smoothedIncome,
            currentMonthNetIncome: currentIncome,
            bufferBalance: profile.bufferBalance,
            bufferTarget: bufferTarget,
            bufferCoverage: coverage,
            currentMonthSurplus: surplus,
            currentMonthDeficit: deficit,
            taxProvision: taxProvision,
            window: selectedWindow,
            bufferStatus: bufferStatus(coverage: coverage, target: profile.bufferTargetMultiplier)
        )
    }

    public static func reminders(
        for profile: FreelancerProfile,
        view: FreelancerSmoothedView,
        asOf date: Date = Date(),
        calendar: Calendar = .current
    ) -> [FreelancerReminder] {
        var reminders: [FreelancerReminder] = []

        if view.bufferCoverage < min(1, profile.bufferTargetMultiplier) {
            reminders.append(.lowBuffer(monthsCovered: view.bufferCoverage))
        }

        if view.taxProvision > 0 {
            reminders.append(
                .taxDeadline(
                    amount: view.taxProvision,
                    dueDate: taxDeadline(after: date, calendar: calendar)
                )
            )
        }

        if let pattern = slowSeasonPattern(profile.monthlyIncomes) {
            reminders.append(.slowSeasonAlert(historicalPattern: pattern))
        }

        return reminders
    }
}

private extension FreelancerIncomeSmoother {
    static func averageNetIncome(_ incomes: [MonthlyIncome]) -> Decimal {
        guard incomes.isEmpty == false else {
            return 0
        }
        return incomes.reduce(Decimal(0)) { $0 + $1.netAmount } / Decimal(incomes.count)
    }

    static func coverageMonths(bufferBalance: Decimal, smoothedIncome: Decimal) -> Double {
        guard smoothedIncome > 0 else {
            return 0
        }

        let decimalCoverage = bufferBalance / smoothedIncome
        return NSDecimalNumber(decimal: decimalCoverage).doubleValue
    }

    static func bufferStatus(coverage: Double, target: Double) -> FreelancerBufferStatus {
        if coverage < 1 {
            return .danger
        } else if coverage < target {
            return .warning
        } else {
            return .healthy
        }
    }

    static func taxDeadline(after date: Date, calendar: Calendar) -> Date {
        let components = calendar.dateComponents([.year], from: date)
        let currentYear = components.year ?? 1970
        let candidate = DateComponents(
            calendar: calendar,
            year: currentYear,
            month: 4,
            day: 30
        ).date ?? date

        if candidate > date {
            return candidate
        }

        return DateComponents(
            calendar: calendar,
            year: currentYear + 1,
            month: 4,
            day: 30
        ).date ?? date
    }

    static func slowSeasonPattern(_ incomes: [MonthlyIncome]) -> String? {
        let sorted = incomes.sorted { $0.month < $1.month }
        guard sorted.count >= 6 else {
            return nil
        }

        let recent = Array(sorted.suffix(3))
        let previous = Array(sorted.dropLast(3).suffix(3))
        let recentAverage = averageNetIncome(recent)
        let previousAverage = averageNetIncome(previous)

        guard previousAverage > 0, recentAverage < previousAverage * Decimal(0.7) else {
            return nil
        }

        return "freelancer.reminder.slowSeason"
    }

    static func decimal(_ value: Double) -> Decimal {
        Decimal(value)
    }
}
