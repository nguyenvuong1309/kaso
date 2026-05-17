// swift-tools-version: 6.0

import PackageDescription

let tca: Target.Dependency = .product(
    name: "ComposableArchitecture",
    package: "swift-composable-architecture"
)
let featureResources: [Resource] = [.process("../Resources")]
let libraryProductNames = [
    "KasoFoundation", "KasoLogging", "KasoDesignSystem",
    "AppearanceDomain", "AuthDomain", "GoalDomain", "InsightDomain",
    "SubscriptionDomain", "TransactionDomain", "WellnessDomain",
    "WealthDomain", "DebtDomain", "InvestmentDomain",
    "PhantomExpenseDomain", "CompatibilityDomain", "FreelancerDomain",
    "SleepCorrelationDomain", "LegacyDomain", "BudgetDomain",
    "OnboardingDomain", "RoundUpDomain", "GuiltFreeBudgetDomain",
    "CoolingOffDomain", "MoodJournalDomain", "RegretScoreDomain",
    "WhatIfDomain", "SpendingCalendarDomain",
    "PersistenceKit", "AppearanceFeature",
    "AuthFeature", "BenchmarkFeature", "OnboardingFeature", "KasoRootFeature",
    "FinancialAssistantFeature", "TransactionFeature", "WealthFeature", "DebtFeature",
    "InvestmentFeature", "PhantomExpenseFeature", "CompatibilityFeature",
    "FreelancerFeature", "SleepCorrelationFeature", "LegacyFeature",
    "HoursOfLifeFeature", "RoundUpFeature", "GuiltFreeBudgetFeature",
    "CoolingOffFeature", "MoodJournalFeature", "RegretScoreFeature",
    "WhatIfFeature", "SpendingCalendarFeature",
    "WellnessFeature", "QuickEntryIntent",
]

func sourceTarget(
    _ name: String,
    _ dependencies: [Target.Dependency] = [],
    path: String
) -> Target {
    .target(name: name, dependencies: dependencies, path: path)
}

func featureTarget(
    _ name: String,
    _ dependencies: [Target.Dependency],
    path: String
) -> Target {
    .target(
        name: name,
        dependencies: dependencies,
        path: path,
        resources: featureResources
    )
}

func testTarget(
    _ name: String,
    _ dependencies: [Target.Dependency],
    path: String
) -> Target {
    .testTarget(name: name, dependencies: dependencies, path: path)
}

let persistenceDependencies: [Target.Dependency] = [
    "AppearanceDomain", "AuthDomain", "BudgetDomain", "CoolingOffDomain",
    "DebtDomain", "FreelancerDomain", "GoalDomain", "GuiltFreeBudgetDomain",
    "InvestmentDomain", "KasoFoundation",
    "LegacyDomain", "MoodJournalDomain", "OnboardingDomain", "PhantomExpenseDomain",
    "RegretScoreDomain", "RoundUpDomain", "TransactionDomain", "WealthDomain",
    "WellnessDomain",
]
let persistenceTestDependencies: [Target.Dependency] = [
    "AppearanceDomain", "BudgetDomain", "CoolingOffDomain", "DebtDomain", "GoalDomain",
    "FreelancerDomain", "GuiltFreeBudgetDomain", "InvestmentDomain", "LegacyDomain",
    "MoodJournalDomain", "PersistenceKit", "PhantomExpenseDomain", "RegretScoreDomain",
    "RoundUpDomain", "TransactionDomain", "WealthDomain", "WellnessDomain",
]
let rootFeatureDependencies: [Target.Dependency] = [
    "AppearanceDomain", "AppearanceFeature", "AuthDomain", "AuthFeature",
    "BenchmarkFeature", "BudgetDomain", "CoolingOffDomain", "CoolingOffFeature",
    "DebtFeature", "FinancialAssistantFeature", "FreelancerDomain",
    "FreelancerFeature", "GoalDomain", "GuiltFreeBudgetDomain", "GuiltFreeBudgetFeature",
    "HoursOfLifeFeature", "InvestmentDomain",
    "InvestmentFeature", "KasoDesignSystem", "LegacyDomain", "LegacyFeature",
    "MoodJournalDomain", "MoodJournalFeature",
    "OnboardingDomain", "OnboardingFeature",
    "PhantomExpenseDomain", "PhantomExpenseFeature", "RegretScoreDomain", "RegretScoreFeature",
    "RoundUpDomain", "RoundUpFeature", "SpendingCalendarDomain", "SpendingCalendarFeature",
    "TransactionDomain",
    "SleepCorrelationFeature", "TransactionFeature", "WealthDomain",
    "WealthFeature", "WellnessDomain", "WellnessFeature", "WhatIfDomain", "WhatIfFeature",
    tca,
]
let transactionFeatureDependencies: [Target.Dependency] = [
    "BudgetDomain", "GoalDomain", "InsightDomain", "KasoDesignSystem",
    "SubscriptionDomain", "TransactionDomain", "WellnessDomain", tca,
]

let package = Package(
    name: "Kaso",
    defaultLocalization: "vi",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Kaso", targets: ["Kaso"]),
    ] + libraryProductNames.map { .library(name: $0, targets: [$0]) },
    dependencies: [
        .package(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "1.0.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "Kaso",
            dependencies: [
                "BenchmarkFeature", "DebtFeature", "FinancialAssistantFeature", "FreelancerFeature",
                "HoursOfLifeFeature", "InvestmentFeature", "KasoRootFeature",
                "LegacyFeature", "PersistenceKit", "QuickEntryIntent", "SleepCorrelationDomain",
                "SleepCorrelationFeature",
            ],
            path: "App/Sources",
            resources: featureResources
        ),
        sourceTarget("KasoFoundation", path: "Packages/Core/KasoFoundation/Sources"),
        sourceTarget("KasoLogging", path: "Packages/Core/KasoLogging/Sources"),
        sourceTarget("KasoDesignSystem", path: "Packages/DesignSystem/KasoDesignSystem/Sources"),
        sourceTarget("AppearanceDomain", path: "Packages/Domain/AppearanceDomain/Sources"),
        testTarget("AppearanceDomainTests", ["AppearanceDomain"], path: "Packages/Domain/AppearanceDomain/Tests"),
        sourceTarget("AuthDomain", path: "Packages/Domain/AuthDomain/Sources"),
        testTarget("AuthDomainTests", ["AuthDomain"], path: "Packages/Domain/AuthDomain/Tests"),
        sourceTarget("GoalDomain", path: "Packages/Domain/GoalDomain/Sources"),
        testTarget("GoalDomainTests", ["GoalDomain"], path: "Packages/Domain/GoalDomain/Tests"),
        sourceTarget("InsightDomain", ["TransactionDomain"], path: "Packages/Domain/InsightDomain/Sources"),
        testTarget(
            "InsightDomainTests",
            ["InsightDomain", "TransactionDomain"],
            path: "Packages/Domain/InsightDomain/Tests"
        ),
        sourceTarget("SubscriptionDomain", ["TransactionDomain"], path: "Packages/Domain/SubscriptionDomain/Sources"),
        testTarget(
            "SubscriptionDomainTests",
            ["SubscriptionDomain", "TransactionDomain"],
            path: "Packages/Domain/SubscriptionDomain/Tests"
        ),
        sourceTarget("TransactionDomain", path: "Packages/Domain/TransactionDomain/Sources"),
        testTarget("TransactionDomainTests", ["TransactionDomain"], path: "Packages/Domain/TransactionDomain/Tests"),
        sourceTarget("WellnessDomain", ["TransactionDomain"], path: "Packages/Domain/WellnessDomain/Sources"),
        testTarget(
            "WellnessDomainTests",
            ["TransactionDomain", "WellnessDomain"],
            path: "Packages/Domain/WellnessDomain/Tests"
        ),
        sourceTarget("WealthDomain", path: "Packages/Domain/WealthDomain/Sources"),
        testTarget("WealthDomainTests", ["WealthDomain"], path: "Packages/Domain/WealthDomain/Tests"),
        sourceTarget("DebtDomain", ["WealthDomain"], path: "Packages/Domain/DebtDomain/Sources"),
        testTarget("DebtDomainTests", ["DebtDomain", "WealthDomain"], path: "Packages/Domain/DebtDomain/Tests"),
        sourceTarget("InvestmentDomain", ["WealthDomain"], path: "Packages/Domain/InvestmentDomain/Sources"),
        testTarget(
            "InvestmentDomainTests",
            ["InvestmentDomain", "WealthDomain"],
            path: "Packages/Domain/InvestmentDomain/Tests"
        ),
        sourceTarget("PhantomExpenseDomain", path: "Packages/Domain/PhantomExpenseDomain/Sources"),
        testTarget(
            "PhantomExpenseDomainTests",
            ["PhantomExpenseDomain"],
            path: "Packages/Domain/PhantomExpenseDomain/Tests"
        ),
        sourceTarget("CompatibilityDomain", path: "Packages/Domain/CompatibilityDomain/Sources"),
        testTarget(
            "CompatibilityDomainTests",
            ["CompatibilityDomain"],
            path: "Packages/Domain/CompatibilityDomain/Tests"
        ),
        sourceTarget("FreelancerDomain", path: "Packages/Domain/FreelancerDomain/Sources"),
        testTarget(
            "FreelancerDomainTests",
            ["FreelancerDomain"],
            path: "Packages/Domain/FreelancerDomain/Tests"
        ),
        sourceTarget("SleepCorrelationDomain", ["TransactionDomain"], path: "Packages/Domain/SleepCorrelationDomain/Sources"),
        testTarget(
            "SleepCorrelationDomainTests",
            ["SleepCorrelationDomain", "TransactionDomain"],
            path: "Packages/Domain/SleepCorrelationDomain/Tests"
        ),
        sourceTarget("LegacyDomain", path: "Packages/Domain/LegacyDomain/Sources"),
        testTarget(
            "LegacyDomainTests",
            ["LegacyDomain"],
            path: "Packages/Domain/LegacyDomain/Tests"
        ),
        sourceTarget("BudgetDomain", ["TransactionDomain"], path: "Packages/Domain/BudgetDomain/Sources"),
        testTarget(
            "BudgetDomainTests",
            ["BudgetDomain", "TransactionDomain"],
            path: "Packages/Domain/BudgetDomain/Tests"
        ),
        sourceTarget("OnboardingDomain", ["TransactionDomain"], path: "Packages/Domain/OnboardingDomain/Sources"),
        testTarget(
            "OnboardingDomainTests",
            ["OnboardingDomain", "TransactionDomain"],
            path: "Packages/Domain/OnboardingDomain/Tests"
        ),
        sourceTarget("RoundUpDomain", path: "Packages/Domain/RoundUpDomain/Sources"),
        testTarget(
            "RoundUpDomainTests",
            ["RoundUpDomain"],
            path: "Packages/Domain/RoundUpDomain/Tests"
        ),
        sourceTarget(
            "GuiltFreeBudgetDomain",
            path: "Packages/Domain/GuiltFreeBudgetDomain/Sources"
        ),
        testTarget(
            "GuiltFreeBudgetDomainTests",
            ["GuiltFreeBudgetDomain"],
            path: "Packages/Domain/GuiltFreeBudgetDomain/Tests"
        ),
        sourceTarget("CoolingOffDomain", path: "Packages/Domain/CoolingOffDomain/Sources"),
        testTarget(
            "CoolingOffDomainTests",
            ["CoolingOffDomain"],
            path: "Packages/Domain/CoolingOffDomain/Tests"
        ),
        sourceTarget("MoodJournalDomain", path: "Packages/Domain/MoodJournalDomain/Sources"),
        testTarget(
            "MoodJournalDomainTests",
            ["MoodJournalDomain"],
            path: "Packages/Domain/MoodJournalDomain/Tests"
        ),
        sourceTarget("RegretScoreDomain", path: "Packages/Domain/RegretScoreDomain/Sources"),
        testTarget(
            "RegretScoreDomainTests",
            ["RegretScoreDomain"],
            path: "Packages/Domain/RegretScoreDomain/Tests"
        ),
        sourceTarget("WhatIfDomain", path: "Packages/Domain/WhatIfDomain/Sources"),
        testTarget(
            "WhatIfDomainTests",
            ["WhatIfDomain"],
            path: "Packages/Domain/WhatIfDomain/Tests"
        ),
        sourceTarget("SpendingCalendarDomain", path: "Packages/Domain/SpendingCalendarDomain/Sources"),
        testTarget(
            "SpendingCalendarDomainTests",
            ["SpendingCalendarDomain"],
            path: "Packages/Domain/SpendingCalendarDomain/Tests"
        ),
        sourceTarget("PersistenceKit", persistenceDependencies, path: "Packages/Data/PersistenceKit/Sources"),
        testTarget("PersistenceKitTests", persistenceTestDependencies, path: "Packages/Data/PersistenceKit/Tests"),
        featureTarget(
            "AuthFeature",
            ["AuthDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/AuthFeature/Sources"
        ),
        testTarget("AuthFeatureTests", ["AuthFeature", tca], path: "Packages/Features/AuthFeature/Tests"),
        featureTarget(
            "AppearanceFeature",
            ["AppearanceDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/AppearanceFeature/Sources"
        ),
        testTarget(
            "AppearanceFeatureTests",
            ["AppearanceFeature", tca],
            path: "Packages/Features/AppearanceFeature/Tests"
        ),
        featureTarget(
            "BenchmarkFeature",
            ["InsightDomain", "KasoDesignSystem", "TransactionDomain", tca],
            path: "Packages/Features/BenchmarkFeature/Sources"
        ),
        testTarget(
            "BenchmarkFeatureTests",
            ["BenchmarkFeature", "InsightDomain", "TransactionDomain", tca],
            path: "Packages/Features/BenchmarkFeature/Tests"
        ),
        featureTarget(
            "FinancialAssistantFeature",
            ["InsightDomain", "KasoDesignSystem", "TransactionDomain", tca],
            path: "Packages/Features/FinancialAssistantFeature/Sources"
        ),
        testTarget(
            "FinancialAssistantFeatureTests",
            ["FinancialAssistantFeature", "InsightDomain", "TransactionDomain", tca],
            path: "Packages/Features/FinancialAssistantFeature/Tests"
        ),
        featureTarget(
            "OnboardingFeature",
            ["KasoDesignSystem", "OnboardingDomain", "TransactionDomain", tca],
            path: "Packages/Features/OnboardingFeature/Sources"
        ),
        testTarget(
            "OnboardingFeatureTests",
            ["OnboardingDomain", "OnboardingFeature", "TransactionDomain", tca],
            path: "Packages/Features/OnboardingFeature/Tests"
        ),
        featureTarget("KasoRootFeature", rootFeatureDependencies, path: "Packages/Features/KasoRootFeature/Sources"),
        testTarget(
            "KasoRootFeatureTests",
            ["BudgetDomain", "KasoRootFeature", "OnboardingDomain", "TransactionDomain", tca],
            path: "Packages/Features/KasoRootFeature/Tests"
        ),
        featureTarget(
            "TransactionFeature",
            transactionFeatureDependencies,
            path: "Packages/Features/TransactionFeature/Sources"
        ),
        testTarget(
            "TransactionFeatureTests",
            ["GoalDomain", "InsightDomain", "SubscriptionDomain", "TransactionFeature", "WellnessDomain", tca],
            path: "Packages/Features/TransactionFeature/Tests"
        ),
        featureTarget(
            "DebtFeature",
            ["DebtDomain", "KasoDesignSystem", "WealthDomain", tca],
            path: "Packages/Features/DebtFeature/Sources"
        ),
        testTarget("DebtFeatureTests", ["DebtFeature", tca], path: "Packages/Features/DebtFeature/Tests"),
        featureTarget(
            "InvestmentFeature",
            ["InvestmentDomain", "KasoDesignSystem", "WealthDomain", tca],
            path: "Packages/Features/InvestmentFeature/Sources"
        ),
        testTarget(
            "InvestmentFeatureTests",
            ["InvestmentDomain", "InvestmentFeature", "WealthDomain", tca],
            path: "Packages/Features/InvestmentFeature/Tests"
        ),
        featureTarget(
            "PhantomExpenseFeature",
            ["KasoDesignSystem", "PhantomExpenseDomain", tca],
            path: "Packages/Features/PhantomExpenseFeature/Sources"
        ),
        testTarget(
            "PhantomExpenseFeatureTests",
            ["PhantomExpenseDomain", "PhantomExpenseFeature", tca],
            path: "Packages/Features/PhantomExpenseFeature/Tests"
        ),
        featureTarget(
            "CompatibilityFeature",
            ["CompatibilityDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/CompatibilityFeature/Sources"
        ),
        testTarget(
            "CompatibilityFeatureTests",
            ["CompatibilityDomain", "CompatibilityFeature", tca],
            path: "Packages/Features/CompatibilityFeature/Tests"
        ),
        featureTarget(
            "FreelancerFeature",
            ["FreelancerDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/FreelancerFeature/Sources"
        ),
        testTarget(
            "FreelancerFeatureTests",
            ["FreelancerDomain", "FreelancerFeature", tca],
            path: "Packages/Features/FreelancerFeature/Tests"
        ),
        featureTarget(
            "SleepCorrelationFeature",
            ["KasoDesignSystem", "SleepCorrelationDomain", "TransactionDomain", tca],
            path: "Packages/Features/SleepCorrelationFeature/Sources"
        ),
        testTarget(
            "SleepCorrelationFeatureTests",
            ["SleepCorrelationDomain", "SleepCorrelationFeature", "TransactionDomain", tca],
            path: "Packages/Features/SleepCorrelationFeature/Tests"
        ),
        featureTarget(
            "LegacyFeature",
            ["KasoDesignSystem", "LegacyDomain", tca],
            path: "Packages/Features/LegacyFeature/Sources"
        ),
        testTarget(
            "LegacyFeatureTests",
            ["LegacyDomain", "LegacyFeature", tca],
            path: "Packages/Features/LegacyFeature/Tests"
        ),
        featureTarget(
            "HoursOfLifeFeature",
            ["KasoDesignSystem", "TransactionDomain", "WellnessDomain", tca],
            path: "Packages/Features/HoursOfLifeFeature/Sources"
        ),
        testTarget(
            "HoursOfLifeFeatureTests",
            ["HoursOfLifeFeature", "TransactionDomain", "WellnessDomain", tca],
            path: "Packages/Features/HoursOfLifeFeature/Tests"
        ),
        featureTarget(
            "RoundUpFeature",
            ["KasoDesignSystem", "RoundUpDomain", tca],
            path: "Packages/Features/RoundUpFeature/Sources"
        ),
        testTarget(
            "RoundUpFeatureTests",
            ["RoundUpDomain", "RoundUpFeature", tca],
            path: "Packages/Features/RoundUpFeature/Tests"
        ),
        featureTarget(
            "GuiltFreeBudgetFeature",
            ["GuiltFreeBudgetDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/GuiltFreeBudgetFeature/Sources"
        ),
        testTarget(
            "GuiltFreeBudgetFeatureTests",
            ["GuiltFreeBudgetDomain", "GuiltFreeBudgetFeature", tca],
            path: "Packages/Features/GuiltFreeBudgetFeature/Tests"
        ),
        featureTarget(
            "CoolingOffFeature",
            ["CoolingOffDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/CoolingOffFeature/Sources"
        ),
        testTarget(
            "CoolingOffFeatureTests",
            ["CoolingOffDomain", "CoolingOffFeature", tca],
            path: "Packages/Features/CoolingOffFeature/Tests"
        ),
        featureTarget(
            "MoodJournalFeature",
            ["KasoDesignSystem", "MoodJournalDomain", tca],
            path: "Packages/Features/MoodJournalFeature/Sources"
        ),
        testTarget(
            "MoodJournalFeatureTests",
            ["MoodJournalDomain", "MoodJournalFeature", tca],
            path: "Packages/Features/MoodJournalFeature/Tests"
        ),
        featureTarget(
            "RegretScoreFeature",
            ["KasoDesignSystem", "RegretScoreDomain", tca],
            path: "Packages/Features/RegretScoreFeature/Sources"
        ),
        testTarget(
            "RegretScoreFeatureTests",
            ["RegretScoreDomain", "RegretScoreFeature", tca],
            path: "Packages/Features/RegretScoreFeature/Tests"
        ),
        featureTarget(
            "WhatIfFeature",
            ["KasoDesignSystem", "WhatIfDomain", tca],
            path: "Packages/Features/WhatIfFeature/Sources"
        ),
        testTarget(
            "WhatIfFeatureTests",
            ["WhatIfDomain", "WhatIfFeature", tca],
            path: "Packages/Features/WhatIfFeature/Tests"
        ),
        featureTarget(
            "SpendingCalendarFeature",
            ["KasoDesignSystem", "SpendingCalendarDomain", tca],
            path: "Packages/Features/SpendingCalendarFeature/Sources"
        ),
        testTarget(
            "SpendingCalendarFeatureTests",
            ["SpendingCalendarDomain", "SpendingCalendarFeature", tca],
            path: "Packages/Features/SpendingCalendarFeature/Tests"
        ),
        featureTarget(
            "WellnessFeature",
            [
                "CompatibilityFeature", "CoolingOffFeature", "FreelancerFeature",
                "GuiltFreeBudgetFeature", "HoursOfLifeFeature",
                "KasoDesignSystem", "LegacyFeature", "MoodJournalFeature",
                "PhantomExpenseFeature", "RegretScoreFeature",
                "RoundUpFeature", "SleepCorrelationFeature",
                "SpendingCalendarFeature", "WhatIfFeature", tca,
            ],
            path: "Packages/Features/WellnessFeature/Sources"
        ),
        testTarget(
            "WellnessFeatureTests",
            [
                "CompatibilityFeature", "CoolingOffFeature", "FreelancerFeature",
                "GuiltFreeBudgetFeature", "HoursOfLifeFeature",
                "LegacyFeature", "MoodJournalFeature", "PhantomExpenseFeature",
                "RegretScoreFeature", "RoundUpFeature", "SleepCorrelationFeature",
                "SpendingCalendarFeature", "WellnessFeature", "WhatIfFeature", tca,
            ],
            path: "Packages/Features/WellnessFeature/Tests"
        ),
        featureTarget(
            "WealthFeature",
            ["KasoDesignSystem", "WealthDomain", tca],
            path: "Packages/Features/WealthFeature/Sources"
        ),
        testTarget("WealthFeatureTests", ["WealthFeature", tca], path: "Packages/Features/WealthFeature/Tests"),
        sourceTarget(
            "QuickEntryIntent",
            ["PersistenceKit", "TransactionDomain"],
            path: "Packages/Features/QuickEntryIntent/Sources"
        ),
        testTarget(
            "QuickEntryIntentTests",
            ["QuickEntryIntent", "PersistenceKit", "TransactionDomain"],
            path: "Packages/Features/QuickEntryIntent/Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
