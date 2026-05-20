import KasoDesignSystem
import MapKit
import SpendingMapDomain
import SwiftUI

struct SpendingMapHeaderCard: View {
    let summary: SpendingMapSummary
    let period: SpendingMapPeriod
    let onPeriodChanged: (SpendingMapPeriod) -> Void
    let onAddTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("spendingMap.header.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer()
                Button(action: onAddTapped) {
                    Label {
                        Text("spendingMap.action.add", bundle: .module)
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .font(.kaso.caption.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .tint(Color.kaso.accent)
            }

            Text("spendingMap.header.subtitle", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)

            Picker(selection: Binding(
                get: { period },
                set: { onPeriodChanged($0) }
            )) {
                ForEach(SpendingMapPeriod.allCases) { value in
                    Text(LocalizedStringKey(value.titleKey), bundle: .module)
                        .tag(value)
                }
            } label: {
                Text("spendingMap.period.label", bundle: .module)
            }
            .pickerStyle(.segmented)

            HStack(spacing: Spacing.lg) {
                SpendingMapMetric(
                    titleKey: "spendingMap.metric.total",
                    value: summary.totalAmount,
                    formatStyle: .currency(code: "VND")
                )
                SpendingMapMetric(
                    titleKey: "spendingMap.metric.entries",
                    integerValue: summary.entryCount
                )
                SpendingMapMetric(
                    titleKey: "spendingMap.metric.hotspots",
                    integerValue: summary.hotspots.count
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SpendingMapMetric: View {
    let titleKey: String
    var value: Decimal?
    var formatStyle: Decimal.FormatStyle.Currency?
    var integerValue: Int?

    init(
        titleKey: String,
        value: Decimal,
        formatStyle: Decimal.FormatStyle.Currency
    ) {
        self.titleKey = titleKey
        self.value = value
        self.formatStyle = formatStyle
        integerValue = nil
    }

    init(titleKey: String, integerValue: Int) {
        self.titleKey = titleKey
        value = nil
        formatStyle = nil
        self.integerValue = integerValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            if let value, let formatStyle {
                Text(value, format: formatStyle)
                    .font(.kaso.body.weight(.semibold))
                    .foregroundStyle(Color.kaso.textPrimary)
            } else if let integerValue {
                Text("\(integerValue)")
                    .font(.kaso.body.weight(.semibold))
                    .foregroundStyle(Color.kaso.textPrimary)
            }
        }
    }
}

struct SpendingMapPreview: View {
    let hotspots: [SpendingMapHotspot]
    @Binding var position: MapCameraPosition

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("spendingMap.map.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            Map(position: $position) {
                ForEach(hotspots) { hotspot in
                    Annotation(
                        formattedAmount(hotspot.totalAmount),
                        coordinate: CLLocationCoordinate2D(
                            latitude: hotspot.latitude,
                            longitude: hotspot.longitude
                        )
                    ) {
                        SpendingMapAnnotation(hotspot: hotspot)
                    }
                }
            }
            .mapStyle(.standard)
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedAmount(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "VND").presentation(.narrow))
    }
}

struct SpendingMapAnnotation: View {
    let hotspot: SpendingMapHotspot

    var body: some View {
        let diameter = 28.0 + hotspot.intensity * 28.0
        ZStack {
            Circle()
                .fill(Color.kaso.accent.opacity(0.18))
                .frame(width: diameter * 1.8, height: diameter * 1.8)
            Circle()
                .fill(Color.kaso.accent.opacity(0.35))
                .frame(width: diameter, height: diameter)
            Text("\(hotspot.entryCount)")
                .font(.kaso.caption.weight(.semibold))
                .foregroundStyle(Color.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(hotspot.entryCount) giao dịch"))
    }
}

struct SpendingMapEmptyStateCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label {
                Text("spendingMap.empty.title", bundle: .module)
                    .font(.kaso.titleMedium)
            } icon: {
                Image(systemName: "mappin.and.ellipse")
            }
            .foregroundStyle(Color.kaso.textPrimary)
            Text("spendingMap.empty.subtitle", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SpendingMapEntryList: View {
    let entries: [SpendingMapEntry]
    let onEdit: (SpendingMapEntry) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("spendingMap.list.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)
            ForEach(entries) { entry in
                KasoCard {
                    SpendingMapEntryRow(
                        entry: entry,
                        onEdit: { onEdit(entry) },
                        onDelete: { onDelete(entry.id) }
                    )
                }
            }
        }
    }
}

struct SpendingMapEntryRow: View {
    let entry: SpendingMapEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(Color.kaso.accent)
                .imageScale(.large)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.label)
                    .font(.kaso.body.weight(.semibold))
                    .foregroundStyle(Color.kaso.textPrimary)
                if let categoryID = entry.categoryID {
                    Text(categoryID)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
                HStack(spacing: Spacing.sm) {
                    Text(entry.amount, format: .currency(code: "VND"))
                        .font(.kaso.caption.weight(.semibold))
                        .foregroundStyle(Color.kaso.textPrimary)
                    Text(entry.occurredAt, format: .dateTime.day().month().year())
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                }
                Text("(\(formatted(entry.latitude)), \(formatted(entry.longitude)))")
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
            Spacer()
            VStack(spacing: Spacing.xs) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .tint(Color.kaso.accent)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatted(_ value: Double) -> String {
        String(format: "%.4f", value)
    }
}
