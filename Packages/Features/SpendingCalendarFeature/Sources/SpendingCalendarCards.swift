import KasoDesignSystem
import SpendingCalendarDomain
import SwiftUI

struct SpendingCalendarHeaderCard: View {
    let month: Date
    let actualTotal: Decimal
    let forecastTotal: Decimal
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left.circle")
                }
                .accessibilityLabel(Text("calendar.previousMonth", bundle: .module))
                Spacer()
                Text(month.formatted(.dateTime.year().month(.wide).locale(.current)))
                    .font(.kaso.titleMedium)
                Spacer()
                Button(action: onNext) {
                    Image(systemName: "chevron.right.circle")
                }
                .accessibilityLabel(Text("calendar.nextMonth", bundle: .module))
            }

            HStack(spacing: Spacing.md) {
                metric(labelKey: "calendar.actualTotal", value: SpendingCalendarFormatters.currency(actualTotal))
                metric(labelKey: "calendar.forecastTotal", value: SpendingCalendarFormatters.currency(forecastTotal))
            }

            Button(action: onToday) {
                Label {
                    Text("calendar.today", bundle: .module)
                } icon: {
                    Image(systemName: "calendar")
                }
            }
            .font(.kaso.caption)
        }
    }

    @ViewBuilder
    private func metric(labelKey: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(labelKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            Text(value)
                .font(.kaso.numericMedium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SpendingCalendarGrid: View {
    let month: SpendingCalendarMonth
    let referenceDate: Date
    let selectedDate: Date?
    let onSelectDay: (Date?) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdaySymbols = Calendar.current.shortStandaloneWeekdaySymbols

    var body: some View {
        VStack(spacing: Spacing.sm) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0 ..< leadingEmptyDays, id: \.self) { _ in
                    Color.clear.frame(height: 44)
                }
                ForEach(month.days) { day in
                    SpendingCalendarDayCell(
                        day: day,
                        isToday: Calendar.current.isDate(day.date, inSameDayAs: referenceDate),
                        isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: day.date) } ?? false,
                        onTap: { onSelectDay(day.date) }
                    )
                }
            }
        }
    }

    private var leadingEmptyDays: Int {
        guard let firstDay = month.days.first?.date else {
            return 0
        }
        let weekday = Calendar.current.component(.weekday, from: firstDay)
        let firstWeekday = Calendar.current.firstWeekday
        return (weekday - firstWeekday + 7) % 7
    }
}

private struct SpendingCalendarDayCell: View {
    let day: DailySpending
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: day.date))")
                    .font(.caption)
                    .fontWeight(isToday ? .semibold : .regular)
                Circle()
                    .fill(indicatorColor)
                    .frame(width: indicatorSize, height: indicatorSize)
                    .opacity(day.total > 0 ? 1 : 0.15)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(background)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isToday ? Color.kaso.accent : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            Text(
                String(
                    format: NSLocalizedString(
                        "calendar.cellLabel",
                        bundle: .module,
                        comment: ""
                    ),
                    day.date.formatted(date: .abbreviated, time: .omitted),
                    SpendingCalendarFormatters.currency(day.total)
                )
            )
        )
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(isSelected ? Color.kaso.surfaceSecondary.opacity(0.8) : Color.clear)
    }

    private var indicatorColor: Color {
        switch day.kind {
        case .actual:
            switch day.intensity {
            case .empty:
                return Color.kaso.textSecondary.opacity(0.3)
            case .low:
                return Color.kaso.positive
            case .medium:
                return Color.kaso.accent
            case .high:
                return Color.kaso.destructive
            }
        case .forecast:
            return day.total > 0 ? Color.kaso.warning : Color.kaso.textSecondary.opacity(0.2)
        }
    }

    private var indicatorSize: CGFloat {
        switch day.intensity {
        case .empty:
            4
        case .low:
            6
        case .medium:
            8
        case .high:
            10
        }
    }
}

struct SpendingCalendarTopDayCard: View {
    let day: DailySpending

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("calendar.topDay.headline", bundle: .module)
                .font(.kaso.titleMedium)
            Text(day.date.formatted(date: .complete, time: .omitted))
                .font(.kaso.body)
            Text(SpendingCalendarFormatters.currency(day.total))
                .font(.kaso.numericLarge)
                .foregroundStyle(Color.kaso.destructive)
        }
    }
}

struct SpendingCalendarDayCard: View {
    let day: DailySpending

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(day.date.formatted(date: .complete, time: .omitted))
                .font(.kaso.titleMedium)

            HStack {
                Text(day.kind == .actual
                    ? Text("calendar.day.actual", bundle: .module)
                    : Text("calendar.day.forecast", bundle: .module)
                )
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                Text(SpendingCalendarFormatters.currency(day.total))
                    .font(.kaso.numericMedium)
            }

            if day.items.isEmpty {
                Text("calendar.day.empty", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(day.items) { item in
                        HStack {
                            Text(item.label)
                                .font(.kaso.body)
                            Spacer()
                            Text(SpendingCalendarFormatters.currency(item.amount))
                                .font(.kaso.caption)
                        }
                    }
                }
            }
        }
    }
}
