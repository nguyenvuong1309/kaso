import KasoDesignSystem
import SmartSearchDomain
import SwiftUI

struct SmartSearchHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("smartSearch.header.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)
            Text("smartSearch.header.subtitle", bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SmartSearchInputCard: View {
    @Binding var text: String
    let onParse: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("smartSearch.input.title", bundle: .module)
                .font(.kaso.body.weight(.semibold))
                .foregroundStyle(Color.kaso.textPrimary)
            TextField(
                "smartSearch.input.placeholder",
                text: $text,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .onSubmit(onParse)

            Button(action: onParse) {
                Label {
                    Text("smartSearch.action.parse", bundle: .module)
                } icon: {
                    Image(systemName: "wand.and.stars")
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SmartSearchExamplesCard: View {
    let onSelect: (String) -> Void

    private let examples = [
        "cà phê tuần trước",
        "Grab tháng 3",
        "ăn sáng hôm qua",
        "Spotify năm ngoái",
        "shopping last month",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("smartSearch.examples.title", bundle: .module)
                .font(.kaso.body.weight(.semibold))
                .foregroundStyle(Color.kaso.textPrimary)

            ForEach(examples, id: \.self) { example in
                Button {
                    onSelect(example)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Color.kaso.accent)
                        Text(example)
                            .font(.kaso.body)
                            .foregroundStyle(Color.kaso.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.left.square")
                            .foregroundStyle(Color.kaso.textSecondary)
                    }
                    .padding(Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .fill(Color.kaso.accent.opacity(0.06))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SmartSearchResultCard: View {
    let query: SmartSearchQuery

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("smartSearch.result.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.kaso.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("smartSearch.result.keyword", bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    Text(query.keyword.isEmpty ? "—" : query.keyword)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)
                }
            }

            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.kaso.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("smartSearch.result.dateRange", bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.textSecondary)
                    if let range = query.dateRange {
                        Text(
                            "\(range.start.formatted(.dateTime.day().month().year())) → "
                                + range.end.formatted(.dateTime.day().month().year())
                        )
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textPrimary)
                    } else {
                        Text("smartSearch.result.noDate", bundle: .module)
                            .font(.kaso.body)
                            .foregroundStyle(Color.kaso.textSecondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
