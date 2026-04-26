import ComposableArchitecture
import OnboardingDomain

private enum OnboardingProfileRepositoryKey: DependencyKey {
    static let liveValue = OnboardingProfileRepository.empty
    static let previewValue = OnboardingProfileRepository.preview
    static let testValue = OnboardingProfileRepository.empty
}

public extension OnboardingProfileRepository {
    static let preview = OnboardingProfileRepository(
        load: { OnboardingProfile.preview },
        save: { _ in },
        clear: {}
    )
}

public extension DependencyValues {
    var onboardingProfileRepository: OnboardingProfileRepository {
        get { self[OnboardingProfileRepositoryKey.self] }
        set { self[OnboardingProfileRepositoryKey.self] = newValue }
    }
}
