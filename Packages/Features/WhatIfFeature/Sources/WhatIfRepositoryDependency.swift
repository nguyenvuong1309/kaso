import ComposableArchitecture
import WhatIfDomain

private enum WhatIfBaselineClientKey: DependencyKey {
    static let liveValue = WhatIfBaselineClient.empty
    static let previewValue = WhatIfBaselineClient.preview
    static let testValue = WhatIfBaselineClient.empty
}

public extension WhatIfBaselineClient {
    static let preview = WhatIfBaselineClient(
        load: {
            WhatIfBaseline(monthlyIncome: 20_000_000, monthlyExpenses: 13_500_000)
        }
    )
}

public extension DependencyValues {
    var whatIfBaselineClient: WhatIfBaselineClient {
        get { self[WhatIfBaselineClientKey.self] }
        set { self[WhatIfBaselineClientKey.self] = newValue }
    }
}
