import GamificationDomain
import KasoDesignSystem
import SwiftUI

struct GamificationWeeklyChallengeCard: View {
    let challenge: WeeklyChallenge?
    let referenceDate: Date
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline) {
                Text("gamification.weeklyChallenge.title", bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer()
                if let challenge, !challenge.isCompleted {
                    let days = challenge.daysRemaining(referenceDate: referenceDate)
                    Text("gamification.weeklyChallenge.daysLeft \(days)", bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.accent)
                }
            }

            if let challenge {
                challengeContent(challenge: challenge)
            } else {
                Text("gamification.weeklyChallenge.empty", bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func challengeContent(challenge: WeeklyChallenge) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: challenge.kind.symbolName)
                .font(.system(size: ChallengeLayout.iconSize, weight: .semibold))
                .foregroundStyle(challenge.isCompleted ? Color.kaso.positive : Color.kaso.accent)
                .frame(
                    width: ChallengeLayout.iconBoxSize,
                    height: ChallengeLayout.iconBoxSize
                )
                .background(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(
                            (challenge.isCompleted ? Color.kaso.positive : Color.kaso.accent)
                                .opacity(0.18)
                        )
                )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(challenge.kind.titleKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)
                Text(LocalizedStringKey(challenge.kind.descriptionKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }

        WeeklyChallengeProgressBar(
            ratio: challenge.ratio,
            isCompleted: challenge.isCompleted,
            reduceMotion: reduceMotion
        )

        HStack {
            Text("\(challenge.displayProgress)/\(challenge.target)")
                .font(.kaso.numericMedium)
                .foregroundStyle(Color.kaso.textPrimary)
            Spacer()
            if challenge.isCompleted {
                Label {
                    Text("gamification.weeklyChallenge.completed", bundle: .module)
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                }
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.positive)
            } else {
                Text(
                    "gamification.weeklyChallenge.reward \(challenge.kind.rewardPoints)",
                    bundle: .module
                )
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
            }
        }
    }

    private enum ChallengeLayout {
        static let iconSize: CGFloat = 24
        static let iconBoxSize: CGFloat = 44
    }
}

struct WeeklyChallengeProgressBar: View {
    let ratio: Double
    let isCompleted: Bool
    let reduceMotion: Bool
    @State private var animatedRatio: Double = 0

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.kaso.textSecondary.opacity(0.15))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isCompleted
                                ? [Color.kaso.positive, Color.kaso.positive.opacity(0.7)]
                                : [Color.kaso.accent, Color.kaso.positive],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, proxy.size.width * animatedRatio))
            }
        }
        .frame(height: BarLayout.height)
        .onAppear {
            update(animated: !reduceMotion)
        }
        .onChange(of: ratio) { _, _ in
            update(animated: !reduceMotion)
        }
    }

    private func update(animated: Bool) {
        if animated {
            withAnimation(.easeInOut(duration: 0.45)) {
                animatedRatio = ratio
            }
        } else {
            animatedRatio = ratio
        }
    }

    private enum BarLayout {
        static let height: CGFloat = 8
    }
}
