import ComposableArchitecture
import Foundation
import MoneyPersonalityDomain

private enum MoneyPersonalityContextClientKey: DependencyKey {
    static let liveValue = MoneyPersonalityContextClient.empty
    static let previewValue = MoneyPersonalityContextClient.preview
    static let testValue = MoneyPersonalityContextClient.empty
}

public extension DependencyValues {
    var moneyPersonalityContextClient: MoneyPersonalityContextClient {
        get { self[MoneyPersonalityContextClientKey.self] }
        set { self[MoneyPersonalityContextClientKey.self] = newValue }
    }
}
