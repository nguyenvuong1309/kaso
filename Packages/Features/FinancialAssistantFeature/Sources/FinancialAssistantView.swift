import SwiftUI
import ComposableArchitecture
import InsightDomain
import KasoDesignSystem

public struct FinancialAssistantView: View {
    @Bindable private var store: StoreOf<FinancialAssistantFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<FinancialAssistantFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.md) {
                        FinancialAssistantIntroCard()

                        if store.messages.isEmpty {
                            suggestedPrompts
                        } else {
                            ForEach(store.messages) { message in
                                FinancialAssistantMessageBubble(message: message)
                            }
                        }

                        if store.isLoading {
                            loadingBubble
                        }

                        if let errorMessageKey = store.errorMessageKey {
                            Text(LocalizedStringKey(errorMessageKey), bundle: .module)
                                .font(.kaso.caption)
                                .foregroundStyle(Color.kaso.destructive)
                        }
                    }
                    .padding(Spacing.md)
                }

                inputBar
            }
            .background(Color.kaso.surfacePrimary)
            .navigationTitle(Text("assistant.title", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.sheetDismissed)
                        dismiss()
                    } label: {
                        Text("assistant.close", bundle: .module)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.clearConversationButtonTapped)
                    } label: {
                        Text("assistant.clear", bundle: .module)
                    }
                    .disabled(store.messages.isEmpty && store.errorMessageKey == nil)
                }
            }
        }
    }

    private var suggestedPrompts: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("assistant.prompts.title", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)

            ForEach(FinancialAssistantSuggestedPrompt.allCases) { prompt in
                Button {
                    store.send(.suggestedPromptTapped(prompt))
                } label: {
                    HStack {
                        Text(LocalizedStringKey(prompt.titleKey), bundle: .module)
                            .font(.kaso.body)
                            .foregroundStyle(Color.kaso.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.forward")
                            .foregroundStyle(Color.kaso.textSecondary)
                    }
                    .padding(Spacing.md)
                    .background(
                        Color.kaso.surfaceSecondary,
                        in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingBubble: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .controlSize(.small)

            Text("assistant.loading", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
        }
        .padding(Spacing.md)
        .background(
            Color.kaso.surfaceSecondary,
            in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
        )
    }

    private var inputBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField(
                text: draftQuestionBinding,
                prompt: Text("assistant.input.placeholder", bundle: .module)
            ) {
                Text("assistant.input.label", bundle: .module)
            }
            .textFieldStyle(.roundedBorder)
            .submitLabel(.send)
            .onSubmit {
                store.send(.sendButtonTapped)
            }

            Button {
                store.send(.sendButtonTapped)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.kaso.titleMedium)
            }
            .disabled(store.canSend == false)
            .accessibilityLabel(Text("assistant.send", bundle: .module))
        }
        .padding(Spacing.md)
        .background(Color.kaso.surfaceSecondary)
    }

    private var draftQuestionBinding: Binding<String> {
        Binding(
            get: { store.draftQuestion },
            set: { store.send(.draftQuestionChanged($0)) }
        )
    }
}

private struct FinancialAssistantIntroCard: View {
    var body: some View {
        KasoCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label {
                    Text("assistant.empty.title", bundle: .module)
                        .font(.kaso.titleMedium)
                        .foregroundStyle(Color.kaso.textPrimary)
                } icon: {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.kaso.accent)
                }

                Text("assistant.empty.description", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
        }
    }
}

private struct FinancialAssistantMessageBubble: View {
    let message: FinancialAssistantMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: Spacing.xl)
            }

            content
                .padding(Spacing.md)
                .background(
                    backgroundColor,
                    in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                )

            if message.role == .assistant {
                Spacer(minLength: Spacing.xl)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch message.role {
        case .user:
            Text(message.text)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textPrimary)
        case .assistant:
            if let answer = message.answer {
                FinancialAssistantAnswerCard(answer: answer)
            }
        }
    }

    private var backgroundColor: Color {
        switch message.role {
        case .user:
            Color.kaso.accent.opacity(0.14)
        case .assistant:
            Color.kaso.surfaceSecondary
        }
    }
}
