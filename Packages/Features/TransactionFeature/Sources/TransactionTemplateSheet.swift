import ComposableArchitecture
import KasoDesignSystem
import SwiftUI
import TransactionDomain

struct TransactionTemplateSheet: View {
    @Bindable var store: StoreOf<TransactionFeature>

    var body: some View {
        NavigationStack {
            Group {
                if store.templates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle(Text("transactions.templates.title", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.templateSheetDismissed)
                    } label: {
                        Text("common.cancel", bundle: .module)
                    }
                }
            }
        }
    }

    private var templateList: some View {
        List {
            ForEach(store.templates) { template in
                Button {
                    store.send(.templateSelected(template))
                } label: {
                    TemplateRow(template: template)
                }
                .tint(.primary)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        store.send(.templateDeleteButtonTapped(template.id))
                    } label: {
                        Label {
                            Text("common.delete", bundle: .module)
                        } icon: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))

            Text("transactions.templates.empty.title", bundle: .module)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)

            Text("transactions.templates.empty.subtitle", bundle: .module)
                .font(Font.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct TemplateRow: View {
    let template: TransactionTemplate

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: template.category.symbolName)
                .font(Font.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
                .frame(width: 36, height: 36)
                .background(Color.kaso.surfaceSecondary)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(Font.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                    .lineLimit(1)

                if let note = template.note, note.isEmpty == false {
                    Text(note)
                        .font(Font.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(template.amount, format: .currency(code: "VND"))
                    .font(Font.kaso.body)
                    .foregroundStyle(
                        template.kind == .income
                            ? Color.kaso.positive
                            : Color.kaso.textPrimary
                    )

                Text(LocalizedStringKey(template.kind.nameKey), bundle: .module)
                    .font(Font.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary.opacity(0.6))
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
