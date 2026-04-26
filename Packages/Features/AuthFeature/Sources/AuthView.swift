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
                KasoLogoMark()

                VStack(spacing: Spacing.sm) {
                    AuthWordTypewriterText(
                        localizationKey: "auth.title",
                        font: .kaso.titleLarge,
                        foregroundColor: Color.kaso.textPrimary,
                        startDelay: Layout.titleTypewriterStartDelay,
                        wordDelay: Layout.titleTypewriterWordDelay
                    )

                    AuthWordTypewriterText(
                        localizationKey: "auth.subtitle",
                        font: .kaso.body,
                        foregroundColor: Color.kaso.textSecondary,
                        startDelay: Layout.subtitleTypewriterStartDelay,
                        wordDelay: Layout.subtitleTypewriterWordDelay
                    )
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

private struct KasoLogoMark: View {
    var body: some View {
        Image("KasoLogo", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(
                width: Layout.heroLogoSize,
                height: Layout.heroLogoSize
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Layout.heroLogoRadius,
                    style: .continuous
                )
            )
            .shadow(
                color: Color.kaso.accent.opacity(Layout.heroLogoShadowOpacity),
                radius: Layout.heroLogoShadowRadius,
                y: Layout.heroLogoShadowY
            )
            .accessibilityHidden(true)
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

private struct AuthWordTypewriterText: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale
    @State private var visibleWordCount = 0

    let localizationKey: String
    let font: Font
    let foregroundColor: Color
    let startDelay: Duration
    let wordDelay: Duration

    var body: some View {
        let localizedText = String(
            localized: String.LocalizationValue(localizationKey),
            bundle: .module,
            locale: locale
        )
        let words = words(from: localizedText)

        AuthWordWrapLayout(
            horizontalSpacing: Layout.typewriterHorizontalSpacing,
            verticalSpacing: Layout.typewriterLineSpacing
        ) {
            ForEach(words.indices, id: \.self) { wordIndex in
                wordView(words[wordIndex], at: wordIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: localizedText))
        .task(id: animationIdentifier(for: localizedText)) {
            await animate(words: words)
        }
    }

    private func words(from text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace)
            .map(String.init)
    }

    private func wordView(
        _ word: String,
        at wordIndex: Int
    ) -> some View {
        let isVisible = reduceMotion || wordIndex < visibleWordCount

        return Text(verbatim: word)
            .font(font)
            .foregroundStyle(foregroundColor)
            .scaleEffect(isVisible ? 1 : Layout.typewriterInitialScale)
            .opacity(isVisible ? 1 : 0)
            .blur(radius: isVisible ? 0 : Layout.typewriterInitialBlurRadius)
            .offset(y: isVisible ? 0 : Layout.typewriterInitialOffsetY)
            .animation(typewriterAnimation, value: isVisible)
    }

    private var typewriterAnimation: Animation? {
        guard reduceMotion == false else {
            return nil
        }

        return .spring(
            response: Layout.typewriterResponse,
            dampingFraction: Layout.typewriterDampingFraction
        )
    }

    private func animationIdentifier(for localizedText: String) -> String {
        "\(localizedText)-\(reduceMotion)"
    }

    @MainActor
    private func animate(words: [String]) async {
        guard reduceMotion == false else {
            visibleWordCount = words.count
            return
        }
        guard words.isEmpty == false else {
            visibleWordCount = 0
            return
        }

        visibleWordCount = 0
        try? await Task.sleep(for: startDelay)

        for wordIndex in 1 ... words.count {
            guard Task.isCancelled == false else {
                return
            }

            withAnimation(typewriterAnimation) {
                visibleWordCount = wordIndex
            }
            try? await Task.sleep(for: wordDelay)
        }
    }
}

private struct AuthWordWrapLayout: SwiftUI.Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let sizes = subviewSizes(for: subviews)
        let maxWidth = proposal.width ?? naturalWidth(for: sizes)
        let lines = lines(for: sizes, maxWidth: maxWidth)
        let width = lines.map(\.width).max() ?? 0
        let height = lines
            .map(\.height)
            .reduce(0, +) + verticalSpacing * CGFloat(max(lines.count - 1, 0))

        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let sizes = subviewSizes(for: subviews)
        let lines = lines(for: sizes, maxWidth: bounds.width)
        var yPosition = bounds.minY

        for line in lines {
            var xPosition = bounds.minX + max((bounds.width - line.width) / 2, 0)

            for index in line.range {
                let size = sizes[index]
                subviews[index].place(
                    at: CGPoint(
                        x: xPosition,
                        y: yPosition + max((line.height - size.height) / 2, 0)
                    ),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(
                        width: size.width,
                        height: size.height
                    )
                )
                xPosition += size.width + horizontalSpacing
            }

            yPosition += line.height + verticalSpacing
        }
    }

    private func subviewSizes(for subviews: Subviews) -> [CGSize] {
        subviews.map { subview in
            subview.sizeThatFits(.unspecified)
        }
    }

    private func naturalWidth(for sizes: [CGSize]) -> CGFloat {
        let wordsWidth = sizes.map(\.width).reduce(0, +)
        let spacingWidth = horizontalSpacing * CGFloat(max(sizes.count - 1, 0))
        return wordsWidth + spacingWidth
    }

    private func lines(
        for sizes: [CGSize],
        maxWidth: CGFloat
    ) -> [AuthWordWrapLine] {
        guard sizes.isEmpty == false else {
            return []
        }

        var lines: [AuthWordWrapLine] = []
        var lineStartIndex = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for (index, size) in sizes.enumerated() {
            let spacing = lineWidth == 0 ? 0 : horizontalSpacing
            let proposedWidth = lineWidth + spacing + size.width

            if proposedWidth > maxWidth, lineWidth > 0 {
                lines.append(
                    AuthWordWrapLine(
                        range: lineStartIndex ..< index,
                        width: lineWidth,
                        height: lineHeight
                    )
                )
                lineStartIndex = index
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth = proposedWidth
                lineHeight = max(lineHeight, size.height)
            }
        }

        lines.append(
            AuthWordWrapLine(
                range: lineStartIndex ..< sizes.count,
                width: lineWidth,
                height: lineHeight
            )
        )
        return lines
    }
}

private struct AuthWordWrapLine {
    let range: Range<Int>
    let width: CGFloat
    let height: CGFloat
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
    static let heroLogoSize: CGFloat = Spacing.xl * 2.5
    static let heroLogoRadius: CGFloat = Radius.lg
    static let heroLogoShadowOpacity: Double = 0.18
    static let heroLogoShadowRadius: CGFloat = 12
    static let heroLogoShadowY: CGFloat = 6
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
    static let titleTypewriterStartDelay: Duration = .milliseconds(220)
    static let titleTypewriterWordDelay: Duration = .milliseconds(150)
    static let subtitleTypewriterStartDelay: Duration = .milliseconds(760)
    static let subtitleTypewriterWordDelay: Duration = .milliseconds(112)
    static let typewriterHorizontalSpacing: CGFloat = Spacing.xs
    static let typewriterLineSpacing: CGFloat = Spacing.xs
    static let typewriterInitialScale: CGFloat = 0.985
    static let typewriterInitialOffsetY: CGFloat = Spacing.xs
    static let typewriterInitialBlurRadius: CGFloat = 2.5
    static let typewriterResponse: Double = 0.44
    static let typewriterDampingFraction: Double = 0.92

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
