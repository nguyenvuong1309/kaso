import CommunityChallengeDomain
import KasoDesignSystem
import SwiftUI

struct CommunityChallengeHeaderCard: View {
    let activeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("communityChallenge.header.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)
            Text(subtitleKey, bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)
            Text("communityChallenge.header.privacy", bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.positive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitleKey: LocalizedStringKey {
        activeCount > 0
            ? "communityChallenge.header.subtitle.active"
            : "communityChallenge.header.subtitle.idle"
    }
}

struct CommunityChallengeActiveCard: View {
    let enrollments: [CommunityChallengeEnrollment]
    let onCheckIn: (CommunityChallengeEnrollment) -> Void
    let onLeave: (CommunityChallengeEnrollment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("communityChallenge.active.title", bundle: .module)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.textPrimary)

            ForEach(enrollments) { enrollment in
                if let challenge = CommunityChallengeLibrary.challenge(id: enrollment.challengeID) {
                    CommunityChallengeActiveRow(
                        enrollment: enrollment,
                        challenge: challenge,
                        onCheckIn: { onCheckIn(enrollment) },
                        onLeave: { onLeave(enrollment) }
                    )
                    if enrollment.id != enrollments.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct CommunityChallengeActiveRow: View {
    let enrollment: CommunityChallengeEnrollment
    let challenge: CommunityChallenge
    let onCheckIn: () -> Void
    let onLeave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: challenge.category.iconSystemName)
                    .foregroundStyle(Color.kaso.accent)
                Text(LocalizedStringKey(challenge.titleKey), bundle: .module)
                    .font(.kaso.body.weight(.semibold))
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer()
                Button(role: .destructive, action: onLeave) {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("communityChallenge.action.leave", bundle: .module))
            }

            ProgressView(
                value: enrollment.progress(durationDays: challenge.durationDays)
            )

            HStack {
                Text(
                    "communityChallenge.progress.format",
                    bundle: .module
                )
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                Text("\(enrollment.checkedInDays)/\(challenge.durationDays)")
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer()
                if enrollment.isCompleted {
                    Label {
                        Text("communityChallenge.completed", bundle: .module)
                    } icon: {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.positive)
                } else {
                    Button(action: onCheckIn) {
                        Text("communityChallenge.action.checkIn", bundle: .module)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }
}

struct CommunityChallengeBrowseCard: View {
    let challenge: CommunityChallenge
    let isEnrolled: Bool
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: challenge.category.iconSystemName)
                    .foregroundStyle(Color.kaso.accent)
                Text(LocalizedStringKey(challenge.titleKey), bundle: .module)
                    .font(.kaso.titleMedium)
                    .foregroundStyle(Color.kaso.textPrimary)
                Spacer()
                CommunityChallengeDifficultyBadge(difficulty: challenge.difficulty)
            }

            Text(LocalizedStringKey(challenge.descriptionKey), bundle: .module)
                .font(.kaso.body)
                .foregroundStyle(Color.kaso.textSecondary)

            HStack(alignment: .top, spacing: Spacing.xs) {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(Color.kaso.textSecondary)
                Text(LocalizedStringKey(challenge.goalKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
            }

            HStack {
                Label {
                    Text(
                        "communityChallenge.duration",
                        bundle: .module
                    ) + Text(" \(challenge.durationDays)")
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textSecondary)
                Spacer()
                if isEnrolled {
                    Label {
                        Text("communityChallenge.enrolled", bundle: .module)
                    } icon: {
                        Image(systemName: "checkmark")
                    }
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.positive)
                } else {
                    Button(action: onJoin) {
                        Text("communityChallenge.action.join", bundle: .module)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }
}

private struct CommunityChallengeDifficultyBadge: View {
    let difficulty: CommunityChallengeDifficulty

    var body: some View {
        Text(LocalizedStringKey(difficulty.labelKey), bundle: .module)
            .font(.kaso.caption)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(color.opacity(0.18))
            )
            .foregroundStyle(color)
    }

    private var color: Color {
        switch difficulty {
        case .easy: Color.kaso.positive
        case .medium: Color.kaso.warning
        case .hard: Color.kaso.destructive
        }
    }
}
