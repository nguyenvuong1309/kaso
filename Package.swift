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
    "OnboardingDomain", "PersistenceKit", "AppearanceFeature",
    "AuthFeature", "BenchmarkFeature", "OnboardingFeature", "KasoRootFeature",
    "FinancialAssistantFeature", "TransactionFeature", "WealthFeature", "DebtFeature",
    "InvestmentFeature", "PhantomExpenseFeature", "CompatibilityFeature",
    "FreelancerFeature", "SleepCorrelationFeature", "LegacyFeature",
    "HoursOfLifeFeature", "WellnessFeature",
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
    "AppearanceDomain", "AuthDomain", "BudgetDomain", "DebtDomain",
    "FreelancerDomain", "GoalDomain", "InvestmentDomain", "KasoFoundation",
    "LegacyDomain", "OnboardingDomain", "PhantomExpenseDomain",
    "TransactionDomain", "WealthDomain", "WellnessDomain",
]
let persistenceTestDependencies: [Target.Dependency] = [
    "AppearanceDomain", "BudgetDomain", "DebtDomain", "GoalDomain",
    "FreelancerDomain", "InvestmentDomain", "LegacyDomain", "PersistenceKit",
    "PhantomExpenseDomain", "TransactionDomain", "WealthDomain", "WellnessDomain",
]
let rootFeatureDependencies: [Target.Dependency] = [
    "AppearanceDomain", "AppearanceFeature", "AuthDomain", "AuthFeature",
    "BenchmarkFeature", "BudgetDomain", "DebtFeature", "FinancialAssistantFeature", "FreelancerDomain",
    "FreelancerFeature", "GoalDomain", "HoursOfLifeFeature", "InvestmentDomain",
    "InvestmentFeature", "KasoDesignSystem", "LegacyDomain", "LegacyFeature",
    "OnboardingDomain", "OnboardingFeature",
    "PhantomExpenseDomain", "PhantomExpenseFeature", "TransactionDomain",
    "SleepCorrelationFeature", "TransactionFeature", "WealthDomain",
    "WealthFeature", "WellnessDomain", "WellnessFeature", tca,
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
                "LegacyFeature", "PersistenceKit", "SleepCorrelationDomain",
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
            "WellnessFeature",
            [
                "CompatibilityFeature", "FreelancerFeature", "HoursOfLifeFeature",
                "KasoDesignSystem", "LegacyFeature", "PhantomExpenseFeature",
                "SleepCorrelationFeature", tca,
            ],
            path: "Packages/Features/WellnessFeature/Sources"
        ),
        testTarget(
            "WellnessFeatureTests",
            [
                "CompatibilityFeature", "FreelancerFeature", "HoursOfLifeFeature",
                "LegacyFeature", "PhantomExpenseFeature", "SleepCorrelationFeature",
                "WellnessFeature", tca,
            ],
            path: "Packages/Features/WellnessFeature/Tests"
        ),
        featureTarget(
            "WealthFeature",
            ["KasoDesignSystem", "WealthDomain", tca],
            path: "Packages/Features/WealthFeature/Sources"
        ),
        testTarget("WealthFeatureTests", ["WealthFeature", tca], path: "Packages/Features/WealthFeature/Tests"),
    ],
    swiftLanguageModes: [.v6]
)
