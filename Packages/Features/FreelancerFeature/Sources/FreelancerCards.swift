import SwiftUI
import FreelancerDomain
import KasoDesignSystem

struct FreelancerWindowPicker: View {
    @Binding var selectedWindow: SmoothingWindow

    var body: some View {
        Picker(
            selection: $selectedWindow
        ) {
            ForEach(SmoothingWindow.allCases) { window in
                Text(LocalizedStringKey(window.titleKey), bundle: .module)
                    .tag(window)
            }
        } label: {
            Text("freelancer.window.label", bundle: .module)
        }
        .pickerStyle(.segmented)
    }
}

struct FreelancerSmoothedIncomeCard: View {
    let view: FreelancerSmoothedView?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label {
                Text("freelancer.smoothed.title", bundle: .module)
            } icon: {
                Image(systemName: "waveform.path.ecg")
                    .foregroundStyle(Color.kaso.accent)
            }
            .font(.kaso.titleMedium)

            Text(amount(view?.smoothedMonthlyIncome ?? 0))
                .font(.kaso.numericLarge)
                .foregroundStyle(Color.kaso.textPrimary)
                .contentTransition(.numericText())

            HStack {
                badge(
                    titleKey: "freelancer.currentMonth",
                    value: amount(view?.currentMonthNetIncome ?? 0),
                    color: Color.kaso.accent
                )
                Spacer(minLength: Spacing.sm)
                badge(
                    titleKey: "freelancer.taxProvision",
                    value: amount(view?.taxProvision ?? 0),
                    color: Color.kaso.warning
                )
            }
        }
    }

    private func badge(titleKey: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            Text(value)
                .font(.kaso.numericMedium)
                .foregroundStyle(color)
        }
    }
}

struct FreelancerBufferCard: View {
    let view: FreelancerSmoothedView?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("freelancer.buffer.title", bundle: .module)
                    .font(.kaso.titleMedium)
                Spacer()
                Text(coverageText)
                    .font(.kaso.numericMedium)
                    .foregroundStyle(statusColor)
            }

            ProgressView(value: progress)
                .tint(statusColor)
                .scaleEffect(y: reduceMotion ? 1 : Layout.progressScale)
                .animation(.spring(response: 0.5), value: progress)

            HStack {
                metric("freelancer.buffer.balance", amount(view?.bufferBalance ?? 0))
                Spacer(minLength: Spacing.md)
                metric("freelancer.buffer.target", amount(view?.bufferTarget ?? 0))
            }
        }
    }

    private var progress: Double {
        guard let view, view.bufferTarget > 0 else {
            return 0
        }
        let ratio = NSDecimalNumber(decimal: view.bufferBalance / view.bufferTarget).doubleValue
        return max(0, min(1, ratio))
    }

    private var coverageText: String {
        "\(FreelancerFeatureFormatters.months(view?.bufferCoverage ?? 0))×"
    }

    private var statusColor: Color {
        switch view?.bufferStatus {
        case .healthy:
            Color.kaso.positive
        case .warning:
            Color.kaso.warning
        case .danger, nil:
            Color.kaso.destructive
        }
    }

    private func metric(_ titleKey: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            Text(value)
                .font(.kaso.numericMedium)
        }
    }
}

struct FreelancerIncomeHistoryCard: View {
    let incomes: [MonthlyIncome]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("freelancer.history.title", bundle: .module)
                .font(.kaso.titleMedium)

            if incomes.isEmpty {
                Text("freelancer.history.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                FreelancerIncomeBarChart(incomes: incomes)
                ForEach(incomes.sorted { $0.month > $1.month }.prefix(Layout.rowLimit)) { income in
                    HStack {
                        Text(income.month.id)
                            .font(.kaso.body)
                        Spacer()
                        Text(amount(income.netAmount))
                            .font(.kaso.numericMedium)
                    }
                }
            }
        }
    }
}

struct FreelancerIncomeBarChart: View {
    let incomes: [MonthlyIncome]

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            ForEach(Array(incomes.suffix(Layout.barLimit))) { income in
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(Color.kaso.accent.opacity(Layout.barOpacity))
                    .frame(height: barHeight(for: income))
                    .accessibilityLabel(income.month.id)
            }
        }
        .frame(height: Layout.chartHeight)
        .frame(maxWidth: .infinity)
    }

    private func barHeight(for income: MonthlyIncome) -> CGFloat {
        let maximum = incomes.map(\.netAmount).max() ?? 0
        guard maximum > 0 else {
            return Layout.minimumBarHeight
        }
        let ratio = NSDecimalNumber(decimal: income.netAmount / maximum).doubleValue
        return max(Layout.minimumBarHeight, Layout.chartHeight * ratio)
    }
}

struct FreelancerReminderCard: View {
    let reminders: [FreelancerReminder]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("freelancer.reminder.title", bundle: .module)
                .font(.kaso.titleMedium)

            if reminders.isEmpty {
                Text("freelancer.reminder.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                ForEach(reminders) { reminder in
                    Label {
                        Text(reminderText(reminder))
                            .font(.kaso.body)
                    } icon: {
                        Image(systemName: reminderSymbol(reminder))
                            .foregroundStyle(Color.kaso.warning)
                    }
                }
            }
        }
    }

    private func reminderText(_ reminder: FreelancerReminder) -> String {
        switch reminder {
        case let .taxDeadline(amountValue, dueDate):
            String(
                format: String(localized: "freelancer.reminder.tax", bundle: .module),
                amount(amountValue),
                dueDate.formatted(.dateTime.day().month())
            )
        case let .insuranceRenewal(provider, dueDate):
            String(
                format: String(localized: "freelancer.reminder.insurance", bundle: .module),
                provider,
                dueDate.formatted(.dateTime.day().month())
            )
        case let .lowBuffer(monthsCovered):
            String(
                format: String(localized: "freelancer.reminder.lowBuffer", bundle: .module),
                FreelancerFeatureFormatters.months(monthsCovered)
            )
        case .slowSeasonAlert:
            String(localized: "freelancer.reminder.slowSeason", bundle: .module)
        }
    }

    private func reminderSymbol(_ reminder: FreelancerReminder) -> String {
        switch reminder {
        case .taxDeadline:
            return "calendar.badge.clock"
        case .insuranceRenewal:
            return "shield"
        case .lowBuffer:
            return "exclamationmark.triangle"
        case .slowSeasonAlert:
            return "cloud.rain"
        }
    }
}

private func amount(_ amount: Decimal) -> String {
    FreelancerFeatureFormatters.currency(amount)
}

private enum Layout {
    static let progressScale: CGFloat = 1.6
    static let chartHeight: CGFloat = 120
    static let minimumBarHeight: CGFloat = 8
    static let barLimit = 12
    static let rowLimit = 6
    static let barOpacity: Double = 0.85
}
