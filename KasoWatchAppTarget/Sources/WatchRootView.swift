import KasoWidgetShared
import SwiftUI

struct WatchRootView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    todayCard
                    budgetCard
                    transactionsRow
                    StaleIndicator(updatedAt: snapshot.updatedAt)
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("Kaso")
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hôm nay")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatted(snapshot.totalSpentToday))
                .font(.title3)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Còn lại")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(snapshot.budgetUsedFraction * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(formatted(snapshot.budgetRemaining))
                .font(.headline)
                .minimumScaleFactor(0.7)
            BudgetBar(fraction: snapshot.budgetUsedFraction)
                .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var transactionsRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "list.bullet.rectangle")
                .foregroundStyle(.tint)
            Text("\(snapshot.transactionCountToday) giao dịch")
                .font(.caption)
            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private func formatted(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: snapshot.currencyCode).presentation(.narrow))
    }
}

private struct BudgetBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.secondary.opacity(0.18))
                Capsule().fill(.tint).frame(width: proxy.size.width * fraction)
            }
        }
    }
}

private struct StaleIndicator: View {
    let updatedAt: Date

    var body: some View {
        if updatedAt.timeIntervalSinceReferenceDate <= 0 {
            Label("Chưa có dữ liệu", systemImage: "antenna.radiowaves.left.and.right.slash")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else {
            Label(updatedAt.formatted(.relative(presentation: .named)), systemImage: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
