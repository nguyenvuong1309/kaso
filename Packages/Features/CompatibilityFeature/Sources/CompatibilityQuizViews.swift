import SwiftUI
import CompatibilityDomain
import KasoDesignSystem

struct CompatibilityQuizView: View {
    let titleKey: String
    let question: CompatibilityQuestion
    let currentIndex: Int
    let questionCount: Int
    let progress: Double
    let selectedOptionIndex: Int?
    let errorMessageKey: String?
    let onSelect: (Int) -> Void
    let onNext: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Spacing.md) {
            QuizProgressBar(
                currentIndex: currentIndex,
                questionCount: questionCount,
                progress: progress
            )

            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            QuizQuestionCard(question: question)
                .id(question.id)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))

            VStack(spacing: Spacing.sm) {
                ForEach(question.options.indices, id: \.self) { optionIndex in
                    QuizOptionRow(
                        option: question.options[optionIndex],
                        isSelected: selectedOptionIndex == optionIndex,
                        onTapped: {
                            onSelect(optionIndex)
                        }
                    )
                }
            }

            if let errorMessageKey {
                Text(LocalizedStringKey(errorMessageKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.destructive)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                onNext()
            } label: {
                Label {
                    Text("compatibility.quiz.next", bundle: .module)
                } icon: {
                    Image(systemName: "chevron.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .font(.kaso.body)
            .disabled(selectedOptionIndex == nil)
            .accessibilityIdentifier("compatibility.next")
        }
    }
}

struct QuizProgressBar: View {
    let currentIndex: Int
    let questionCount: Int
    let progress: Double

    var body: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("compatibility.quiz.progress", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                Spacer(minLength: Spacing.md)
                Text("\(currentIndex + 1)/\(questionCount)")
                    .font(.kaso.numericMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.kaso.surfaceSecondary)
                    Capsule()
                        .fill(Color.kaso.accent)
                        .frame(width: proxy.size.width * max(0, min(progress, 1)))
                }
            }
            .frame(height: Layout.progressHeight)

            HStack(spacing: Spacing.xs) {
                ForEach(0..<questionCount, id: \.self) { index in
                    Circle()
                        .fill(index <= currentIndex ? Color.kaso.accent : Color.kaso.surfaceSecondary)
                        .frame(width: Layout.dotSize, height: Layout.dotSize)
                        .scaleEffect(index == currentIndex ? 1.3 : 1)
                }
            }
            .animation(.spring(response: 0.5), value: currentIndex)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct QuizQuestionCard: View {
    let question: CompatibilityQuestion

    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label {
                    Text(LocalizedStringKey(question.dimension.titleKey), bundle: .module)
                } icon: {
                    Image(systemName: question.dimension.symbolName)
                        .foregroundStyle(Color.kaso.category(named: question.dimension.colorName))
                }
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

                Text(LocalizedStringKey(question.textKey), bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct QuizOptionRow: View {
    let option: CompatibilityOption
    let isSelected: Bool
    let onTapped: () -> Void

    var body: some View {
        Button {
            onTapped()
        } label: {
            HStack(spacing: Spacing.md) {
                Text(LocalizedStringKey(option.textKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.kaso.accent : Color.kaso.textSecondary)
                    .scaleEffect(isSelected ? 1.08 : 1)
            }
            .padding(Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    .fill(isSelected ? Color.kaso.accent.opacity(0.16) : Color.kaso.surfaceSecondary)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
        .accessibilityIdentifier("compatibility.option")
    }
}

private enum Layout {
    static let progressHeight: CGFloat = 8
    static let dotSize: CGFloat = 8
}
