import Foundation
import ComposableArchitecture
import CompatibilityDomain

@Reducer
public struct CompatibilityFeature: Sendable {
    @ObservableState
    public struct State: Equatable {
        public var phase: Phase
        public var questions: [CompatibilityQuestion]
        public var userAnswers: [CompatibilityAnswer]
        public var partnerAnswers: [CompatibilityAnswer]
        public var currentQuestionIndex: Int
        public var result: CompatibilityResult?
        public var isAnimatingReveal: Bool
        public var errorMessageKey: String?

        public init(
            phase: Phase = .intro,
            questions: [CompatibilityQuestion] = CompatibilityQuestionBank.defaultQuestions,
            userAnswers: [CompatibilityAnswer] = [],
            partnerAnswers: [CompatibilityAnswer] = [],
            currentQuestionIndex: Int = 0,
            result: CompatibilityResult? = nil,
            isAnimatingReveal: Bool = false,
            errorMessageKey: String? = nil
        ) {
            self.phase = phase
            self.questions = questions
            self.userAnswers = userAnswers
            self.partnerAnswers = partnerAnswers
            self.currentQuestionIndex = currentQuestionIndex
            self.result = result
            self.isAnimatingReveal = isAnimatingReveal
            self.errorMessageKey = errorMessageKey
        }

        public var currentQuestion: CompatibilityQuestion? {
            guard questions.indices.contains(currentQuestionIndex) else {
                return nil
            }
            return questions[currentQuestionIndex]
        }

        public var currentAnswer: CompatibilityAnswer? {
            guard let currentQuestion else {
                return nil
            }
            switch phase {
            case .selfQuiz:
                return userAnswers.first { $0.questionId == currentQuestion.id }
            case .partnerQuiz:
                return partnerAnswers.first { $0.questionId == currentQuestion.id }
            case .intro, .partnerTransition, .result:
                return nil
            }
        }

        public var progress: Double {
            guard questions.isEmpty == false else {
                return 0
            }
            return Double(currentQuestionIndex + 1) / Double(questions.count)
        }

        public var canMoveNext: Bool {
            currentAnswer != nil
        }
    }

    public enum Phase: String, Equatable, Sendable {
        case intro
        case selfQuiz
        case partnerTransition
        case partnerQuiz
        case result
    }

    public enum Action: Equatable, Sendable {
        case startSelfQuiz
        case answerQuestion(questionId: UUID, optionIndex: Int)
        case nextQuestion
        case switchToPartnerQuiz
        case startPartnerQuiz
        case calculateResult
        case resultCalculated(CompatibilityResult)
        case triggerRevealAnimation
        case revealAnimationFinished
        case restartTapped
    }

    @Dependency(\.date) private var date

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .startSelfQuiz:
                state.phase = .selfQuiz
                state.currentQuestionIndex = 0
                state.result = nil
                state.errorMessageKey = nil
                return .none

            case let .answerQuestion(questionId, optionIndex):
                updateAnswer(
                    in: &state,
                    questionId: questionId,
                    optionIndex: optionIndex
                )
                return .none

            case .nextQuestion:
                return nextQuestionEffect(&state)

            case .switchToPartnerQuiz:
                state.phase = .partnerTransition
                state.currentQuestionIndex = 0
                return .none

            case .startPartnerQuiz:
                state.phase = .partnerQuiz
                state.currentQuestionIndex = 0
                return .none

            case .calculateResult:
                let result = CompatibilityCalculator.calculate(
                    questions: state.questions,
                    userAnswers: state.userAnswers,
                    partnerAnswers: state.partnerAnswers,
                    generatedAt: date.now
                )
                return .send(.resultCalculated(result))

            case let .resultCalculated(result):
                state.result = result
                state.phase = .result
                state.isAnimatingReveal = true
                return .none

            case .triggerRevealAnimation:
                state.isAnimatingReveal = true
                return .none

            case .revealAnimationFinished:
                state.isAnimatingReveal = false
                return .none

            case .restartTapped:
                state = State(questions: state.questions)
                return .none
            }
        }
    }

    private func updateAnswer(
        in state: inout State,
        questionId: UUID,
        optionIndex: Int
    ) {
        guard
            let question = state.questions.first(where: { $0.id == questionId }),
            question.options.indices.contains(optionIndex)
        else {
            return
        }

        let respondent: CompatibilityRespondent
        switch state.phase {
        case .selfQuiz:
            respondent = .user
        case .partnerQuiz:
            respondent = .partner
        case .intro, .partnerTransition, .result:
            return
        }

        let answer = CompatibilityAnswer(
            questionId: questionId,
            selectedOptionIndex: optionIndex,
            respondent: respondent
        )
        switch respondent {
        case .user:
            state.userAnswers.removeAll { $0.questionId == questionId }
            state.userAnswers.append(answer)
        case .partner:
            state.partnerAnswers.removeAll { $0.questionId == questionId }
            state.partnerAnswers.append(answer)
        }
    }

    private func nextQuestionEffect(_ state: inout State) -> Effect<Action> {
        guard state.canMoveNext else {
            state.errorMessageKey = "compatibility.error.answerRequired"
            return .none
        }

        state.errorMessageKey = nil
        if state.currentQuestionIndex < state.questions.count - 1 {
            state.currentQuestionIndex += 1
            return .none
        }

        switch state.phase {
        case .selfQuiz:
            return .send(.switchToPartnerQuiz)
        case .partnerQuiz:
            return .send(.calculateResult)
        case .intro, .partnerTransition, .result:
            return .none
        }
    }
}
