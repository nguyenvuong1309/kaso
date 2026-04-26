import AuthenticationServices
import AuthDomain
import ComposableArchitecture
import Foundation
import KasoDesignSystem
import SwiftUI

public struct AuthView: View {
    @Bindable private var store: StoreOf<AuthFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var hasAnimatedIn = false

    public init(store: StoreOf<AuthFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                heroSection
                    .authEntrance(
                        isVisible: hasAnimatedIn,
                        delay: Layout.heroEntranceDelay
                    )
                benefitSection
                    .authEntrance(
                        isVisible: hasAnimatedIn,
                        delay: Layout.benefitEntranceDelay
                    )
                signInSection
                    .authEntrance(
                        isVisible: hasAnimatedIn,
                        delay: Layout.signInEntranceDelay
                    )
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
        }
        .background(authBackground)
        .onAppear {
            startEntranceAnimation()
        }
        .task {
            await store.send(.task).finish()
        }
    }

    private var authBackground: some View {
        AuthBreathingBackground()
    }

    private var heroSection: some View {
        KasoCard {
            VStack(spacing: Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(Color.kaso.accent.opacity(0.14))

                    Circle()
                        .stroke(Color.kaso.accent.opacity(0.28), lineWidth: Layout.borderWidth)

                    Image(systemName: "wallet.pass.fill")
                        .font(.kaso.titleLarge)
                        .foregroundStyle(Color.kaso.accent)
                        .accessibilityHidden(true)
                }
                .frame(
                    width: Layout.heroIconSize,
                    height: Layout.heroIconSize
                )

                VStack(spacing: Spacing.sm) {
                    Text("auth.title", bundle: .module)
                        .font(.kaso.titleLarge)
                        .foregroundStyle(Color.kaso.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("auth.subtitle", bundle: .module)
                        .font(.kaso.body)
                        .foregroundStyle(Color.kaso.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: Spacing.sm) {
                    AuthBadge(
                        iconName: "lock.shield",
                        titleKey: "auth.badge.private"
                    )
                    AuthBadge(
                        iconName: "iphone",
                        titleKey: "auth.badge.local"
                    )
                }
            }
        }
        .movingBorderGlow(cornerRadius: Radius.lg)
    }

    private var benefitSection: some View {
        VStack(spacing: Spacing.md) {
            AuthBenefitRow(
                iconName: "sparkles",
                titleKey: "auth.benefit.fast.title",
                subtitleKey: "auth.benefit.fast.subtitle"
            )
            AuthBenefitRow(
                iconName: "lock.doc",
                titleKey: "auth.benefit.privacy.title",
                subtitleKey: "auth.benefit.privacy.subtitle"
            )
            AuthBenefitRow(
                iconName: "chart.pie",
                titleKey: "auth.benefit.insight.title",
                subtitleKey: "auth.benefit.insight.subtitle"
            )
        }
    }

    private var signInSection: some View {
        KasoCard {
            VStack(spacing: Spacing.md) {
                if let errorMessageKey = store.errorMessageKey {
                    Text(LocalizedStringKey(errorMessageKey), bundle: .module)
                        .font(.kaso.caption)
                        .foregroundStyle(Color.kaso.destructive)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAuthorization(result)
                }
                .signInWithAppleButtonStyle(appleButtonStyle)
                .frame(maxWidth: Layout.signInButtonMaxWidth)
                .frame(height: Layout.signInButtonHeight)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: Layout.signInButtonRadius,
                        style: .continuous
                    )
                )
                .shadow(
                    color: signInButtonShadowColor,
                    radius: Layout.signInButtonShadowRadius,
                    y: Layout.signInButtonShadowY
                )
                .disabled(store.isLoading)

                if store.isLoading {
                    ProgressView()
                        .accessibilityLabel(Text("auth.loading", bundle: .module))
                }

                Text("auth.privacyNote", bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var appleButtonStyle: SignInWithAppleButton.Style {
        colorScheme == .dark ? .white : .black
    }

    private var signInButtonShadowColor: Color {
        colorScheme == .dark ? Color.clear : Color.kaso.accent.opacity(0.12)
    }

    private func startEntranceAnimation() {
        guard hasAnimatedIn == false else {
            return
        }

        if reduceMotion {
            hasAnimatedIn = true
        } else {
            hasAnimatedIn = true
        }
    }

    private func handleAuthorization(
        _ result: Result<ASAuthorization, Error>
    ) {
        switch result {
        case let .success(authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential
            else {
                store.send(.signInFailed("auth.error.invalidCredential"))
                return
            }

            store.send(
                .signInSucceeded(
                    AuthSignInResult(
                        userIdentifier: credential.user,
                        displayName: displayName(from: credential.fullName),
                        email: credential.email
                    )
                )
            )

        case let .failure(error):
            store.send(.signInFailed(messageKey(for: error)))
        }
    }

    private func messageKey(for error: Error) -> String {
        guard let authorizationError = error as? ASAuthorizationError else {
            return "auth.error.signInFailed"
        }

        switch authorizationError.code {
        case .canceled:
            return "auth.error.signInCanceled"
        case .failed:
            return "auth.error.signInAuthorizationFailed"
        case .invalidResponse:
            return "auth.error.invalidResponse"
        case .notHandled:
            return "auth.error.notHandled"
        default:
            return "auth.error.signInFailed"
        }
    }

    private func displayName(
        from components: PersonNameComponents?
    ) -> String? {
        guard let components else {
            return nil
        }

        let displayName = PersonNameComponentsFormatter
            .localizedString(from: components, style: .medium)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return displayName.isEmpty ? nil : displayName
    }
}

private struct AuthBreathingBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            background(phase: Layout.backgroundStaticPhase)
        } else {
            TimelineView(.animation(minimumInterval: Layout.backgroundFrameInterval)) { context in
                background(phase: phase(for: context.date))
            }
        }
    }

    private func background(phase: Double) -> some View {
        let accentOpacity = Layout.backgroundAccentBaseOpacity
            + Layout.backgroundAccentRangeOpacity * phase
        let secondaryOpacity = Layout.backgroundSecondaryBaseOpacity
            + Layout.backgroundSecondaryRangeOpacity * (1 - phase)
        let orbOpacity = Layout.backgroundOrbBaseOpacity
            + Layout.backgroundOrbRangeOpacity * phase

        return ZStack {
            Color.kaso.surfacePrimary

            LinearGradient(
                colors: [
                    Color.kaso.accent.opacity(accentOpacity),
                    Color.kaso.surfacePrimary,
                    Color.kaso.surfaceSecondary.opacity(secondaryOpacity),
                ],
                startPoint: UnitPoint(
                    x: Layout.backgroundStartX + Layout.backgroundStartRangeX * phase,
                    y: Layout.backgroundStartY
                ),
                endPoint: UnitPoint(
                    x: Layout.backgroundEndX,
                    y: Layout.backgroundEndY
                )
            )

            Circle()
                .fill(Color.kaso.accent.opacity(orbOpacity))
                .frame(
                    width: Layout.backgroundOrbSize,
                    height: Layout.backgroundOrbSize
                )
                .blur(radius: Layout.backgroundOrbBlur)
                .offset(
                    x: Layout.backgroundOrbOffsetX * CGFloat(phase),
                    y: Layout.backgroundOrbOffsetY * CGFloat(1 - phase)
                )
        }
        .ignoresSafeArea()
    }

    private func phase(for date: Date) -> Double {
        let cycle = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: Layout.backgroundCycleDuration)
        return (sin(cycle / Layout.backgroundCycleDuration * 2 * Double.pi) + 1) / 2
    }
}

private struct MovingBorderGlowModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.overlay {
            if reduceMotion {
                border(progress: Layout.borderGlowStaticProgress)
            } else {
                TimelineView(.animation(minimumInterval: Layout.borderGlowFrameInterval)) { context in
                    border(progress: progress(for: context.date))
                }
            }
        }
    }

    private func border(progress: Double) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                AngularGradient(
                    stops: [
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowBaseOpacity),
                            location: 0
                        ),
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowBaseOpacity),
                            location: Layout.borderGlowLeadingLocation
                        ),
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowPeakOpacity),
                            location: Layout.borderGlowPeakLocation
                        ),
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowTailOpacity),
                            location: Layout.borderGlowTailLocation
                        ),
                        .init(
                            color: Color.kaso.accent.opacity(Layout.borderGlowBaseOpacity),
                            location: 1
                        ),
                    ],
                    center: .center,
                    startAngle: .degrees(progress * 360),
                    endAngle: .degrees(progress * 360 + 360)
                ),
                lineWidth: Layout.borderGlowWidth
            )
            .shadow(
                color: Color.kaso.accent.opacity(Layout.borderGlowShadowOpacity),
                radius: Layout.borderGlowShadowRadius
            )
    }

    private func progress(for date: Date) -> Double {
        date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: Layout.borderGlowDuration)
            / Layout.borderGlowDuration
    }
}

private struct AuthEntranceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : Layout.entranceInitialScale)
            .offset(y: isVisible ? 0 : Layout.entranceInitialOffsetY)
            .animation(entranceAnimation, value: isVisible)
    }

    private var entranceAnimation: Animation? {
        guard reduceMotion == false else {
            return nil
        }

        return .spring(
            response: Layout.entranceResponse,
            dampingFraction: Layout.entranceDampingFraction
        )
        .delay(delay)
    }
}

private struct AuthBadge: View {
    let iconName: String
    let titleKey: String

    var body: some View {
        Label {
            Text(LocalizedStringKey(titleKey), bundle: .module)
                .font(.kaso.caption)
                .foregroundStyle(Color.kaso.textPrimary)
        } icon: {
            Image(systemName: iconName)
                .foregroundStyle(Color.kaso.accent)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Color.kaso.surfacePrimary,
            in: Capsule()
        )
    }
}

private struct AuthBenefitRow: View {
    let iconName: String
    let titleKey: String
    let subtitleKey: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: iconName)
                .font(.kaso.titleMedium)
                .foregroundStyle(Color.kaso.accent)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(LocalizedStringKey(titleKey), bundle: .module)
                    .font(.kaso.body)
                    .foregroundStyle(Color.kaso.textPrimary)

                Text(LocalizedStringKey(subtitleKey), bundle: .module)
                    .font(.kaso.caption)
                    .foregroundStyle(Color.kaso.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Spacing.sm)
        }
        .padding(Spacing.md)
        .background(
            Color.kaso.surfaceSecondary.opacity(0.86),
            in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
        )
    }
}

private enum Layout {
    static let borderWidth: CGFloat = 1
    static let heroIconSize: CGFloat = Spacing.xl * 2
    static let signInButtonMaxWidth: CGFloat = 360
    static let signInButtonHeight: CGFloat = Spacing.xl + Spacing.lg
    static let signInButtonRadius: CGFloat = Radius.md
    static let signInButtonShadowRadius: CGFloat = 12
    static let signInButtonShadowY: CGFloat = 6

    static let heroEntranceDelay: Double = 0
    static let benefitEntranceDelay: Double = 0.12
    static let signInEntranceDelay: Double = 0.22
    static let entranceInitialScale: CGFloat = 0.97
    static let entranceInitialOffsetY: CGFloat = Spacing.md
    static let entranceResponse: Double = 0.56
    static let entranceDampingFraction: Double = 0.86

    static let backgroundCycleDuration: Double = 7
    static let backgroundFrameInterval: Double = 1 / 30
    static let backgroundStaticPhase: Double = 0.5
    static let backgroundAccentBaseOpacity: Double = 0.16
    static let backgroundAccentRangeOpacity: Double = 0.1
    static let backgroundSecondaryBaseOpacity: Double = 0.64
    static let backgroundSecondaryRangeOpacity: Double = 0.12
    static let backgroundOrbBaseOpacity: Double = 0.08
    static let backgroundOrbRangeOpacity: Double = 0.04
    static let backgroundStartX: Double = 0.06
    static let backgroundStartRangeX: Double = 0.08
    static let backgroundStartY: Double = 0
    static let backgroundEndX: Double = 0.94
    static let backgroundEndY: Double = 1
    static let backgroundOrbSize: CGFloat = Spacing.xl * 6
    static let backgroundOrbBlur: CGFloat = Spacing.xl
    static let backgroundOrbOffsetX: CGFloat = Spacing.xl
    static let backgroundOrbOffsetY: CGFloat = -Spacing.xl

    static let borderGlowStaticProgress: Double = 0.12
    static let borderGlowDuration: Double = 4.8
    static let borderGlowFrameInterval: Double = 1 / 30
    static let borderGlowWidth: CGFloat = 1.5
    static let borderGlowBaseOpacity: Double = 0.16
    static let borderGlowPeakOpacity: Double = 0.78
    static let borderGlowTailOpacity: Double = 0.28
    static let borderGlowLeadingLocation: Double = 0.58
    static let borderGlowPeakLocation: Double = 0.72
    static let borderGlowTailLocation: Double = 0.82
    static let borderGlowShadowOpacity: Double = 0.18
    static let borderGlowShadowRadius: CGFloat = 8
}

private extension View {
    func movingBorderGlow(cornerRadius: CGFloat) -> some View {
        modifier(MovingBorderGlowModifier(cornerRadius: cornerRadius))
    }

    func authEntrance(
        isVisible: Bool,
        delay: Double
    ) -> some View {
        modifier(
            AuthEntranceModifier(
                isVisible: isVisible,
                delay: delay
            )
        )
    }
}

#Preview("Light") {
    AuthView(
        store: Store(initialState: AuthFeature.State()) {
            AuthFeature()
        }
    )
}

#Preview("Dark") {
    AuthView(
        store: Store(initialState: AuthFeature.State()) {
            AuthFeature()
        }
    )
    .preferredColorScheme(.dark)
}

#Preview("Dynamic Type XL") {
    AuthView(
        store: Store(initialState: AuthFeature.State()) {
            AuthFeature()
        }
    )
    .environment(\.dynamicTypeSize, .accessibility1)
}
