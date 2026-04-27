import SwiftUI
import ComposableArchitecture
import CompatibilityDomain
import KasoDesignSystem

public struct CompatibilityView: View {
    @Bindable private var store: StoreOf<CompatibilityFeature>

    public init(store: StoreOf<CompatibilityFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            Group {
                switch store.phase {
                case .intro:
                    CompatibilityIntroView {
                        store.send(.startSelfQuiz)
                    }

                case .selfQuiz:
                    quizView(titleKey: "compatibility.quiz.selfTitle")

                case .partnerTransition:
                    CompatibilityTransitionView {
                        store.send(.startPartnerQuiz)
                    }

                case .partnerQuiz:
                    quizView(titleKey: "compatibility.quiz.partnerTitle")

                case .result:
                    if let result = store.result {
                        CompatibilityResultView(
                            result: result,
                            onRestartTapped: {
                                store.send(.restartTapped)
                            }
                        )
                        .task {
                            try? await Task.sleep(for: .seconds(1.2))
                            store.send(.revealAnimationFinished)
                        }
                    }
                }
            }
            .padding(Spacing.md)
        }
        .background(Color.kaso.surfacePrimary)
        .animation(.easeInOut(duration: 0.2), value: store.phase)
    }

    @ViewBuilder
    private func quizView(titleKey: String) -> some View {
        if let question = store.currentQuestion {
            CompatibilityQuizView(
                titleKey: titleKey,
                question: question,
                currentIndex: store.currentQuestionIndex,
                questionCount: store.questions.count,
                progress: store.progress,
                selectedOptionIndex: store.currentAnswer?.selectedOptionIndex,
                errorMessageKey: store.errorMessageKey,
                onSelect: { optionIndex in
                    store.send(
                        .answerQuestion(
                            questionId: question.id,
                            optionIndex: optionIndex
                        )
                    )
                },
                onNext: {
                    store.send(.nextQuestion)
                }
            )
        }
    }
}

private struct CompatibilityIntroView: View {
    let onStartTapped: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            KasoCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Image(systemName: "person.2.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.kaso.accent)
                        .accessibilityHidden(true)

                    Text("compatibility.intro.title", bundle: .module)
                        .font(.kaso.titleLarge)
                        .foregroundStyle(Color.kaso.textPrimary)

                    Text("compatibility.intro.description", bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        CompatibilityIntroBullet(
                            icon: "slider.horizontal.3",
                            titleKey: "compatibility.intro.bullet.dimensions"
                        )
                        CompatibilityIntroBullet(
                            icon: "exclamationmark.bubble",
                            titleKey: "compatibility.intro.bullet.conflicts"
                        )
                        CompatibilityIntroBullet(
                            icon: "square.and.arrow.up",
                            titleKey: "compatibility.intro.bullet.share"
                        )
                    }
                }
            }

            Button {
                onStartTapped()
            } label: {
                Label {
                    Text("compatibility.intro.start", bundle: .module)
                } icon: {
                    Image(systemName: "arrow.right.circle.fill")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .font(.kaso.body)
            .accessibilityIdentifier("compatibility.start")
        }
    }
}

private struct CompatibilityIntroBullet: View {
    let icon: String
    let titleKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(Color.kaso.accent)
        }
    }
}
