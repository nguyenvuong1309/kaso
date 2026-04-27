// swift-tools-version: 6.0

import PackageDescription

let tca: Target.Dependency = .product(
    name: "ComposableArchitecture",
    package: "swift-composable-architecture"
)
let featureResources: [Resource] = [.process("../Resources")]

let package = Package(
    name: "Kaso",
    defaultLocalization: "vi",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .executable(name: "Kaso", targets: ["Kaso"]),
        .library(name: "KasoFoundation", targets: ["KasoFoundation"]),
        .library(name: "KasoLogging", targets: ["KasoLogging"]),
        .library(name: "KasoDesignSystem", targets: ["KasoDesignSystem"]),
        .library(name: "AppearanceDomain", targets: ["AppearanceDomain"]),
        .library(name: "AuthDomain", targets: ["AuthDomain"]),
        .library(name: "GoalDomain", targets: ["GoalDomain"]),
        .library(name: "InsightDomain", targets: ["InsightDomain"]),
        .library(name: "SubscriptionDomain", targets: ["SubscriptionDomain"]),
        .library(name: "TransactionDomain", targets: ["TransactionDomain"]),
        .library(name: "WellnessDomain", targets: ["WellnessDomain"]),
        .library(name: "WealthDomain", targets: ["WealthDomain"]),
        .library(name: "DebtDomain", targets: ["DebtDomain"]),
        .library(name: "InvestmentDomain", targets: ["InvestmentDomain"]),
        .library(name: "PhantomExpenseDomain", targets: ["PhantomExpenseDomain"]),
        .library(name: "BudgetDomain", targets: ["BudgetDomain"]),
        .library(name: "OnboardingDomain", targets: ["OnboardingDomain"]),
        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
        .library(name: "AppearanceFeature", targets: ["AppearanceFeature"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "KasoRootFeature", targets: ["KasoRootFeature"]),
        .library(name: "TransactionFeature", targets: ["TransactionFeature"]),
        .library(name: "WealthFeature", targets: ["WealthFeature"]),
        .library(name: "DebtFeature", targets: ["DebtFeature"]),
        .library(name: "InvestmentFeature", targets: ["InvestmentFeature"]),
        .library(name: "PhantomExpenseFeature", targets: ["PhantomExpenseFeature"]),
        .library(name: "HoursOfLifeFeature", targets: ["HoursOfLifeFeature"]),
        .library(name: "WellnessFeature", targets: ["WellnessFeature"]),
    ],
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
                "DebtFeature",
                "HoursOfLifeFeature",
                "InvestmentFeature",
                "KasoRootFeature",
                "PersistenceKit",
            ],
            path: "App/Sources",
            resources: featureResources
        ),
        .target(
            name: "KasoFoundation",
            path: "Packages/Core/KasoFoundation/Sources"
        ),
        .target(
            name: "KasoLogging",
            path: "Packages/Core/KasoLogging/Sources"
        ),
        .target(
            name: "KasoDesignSystem",
            path: "Packages/DesignSystem/KasoDesignSystem/Sources"
        ),
        .target(
            name: "AppearanceDomain",
            path: "Packages/Domain/AppearanceDomain/Sources"
        ),
        .testTarget(
            name: "AppearanceDomainTests",
            dependencies: [
                "AppearanceDomain",
            ],
            path: "Packages/Domain/AppearanceDomain/Tests"
        ),
        .target(
            name: "AuthDomain",
            path: "Packages/Domain/AuthDomain/Sources"
        ),
        .testTarget(
            name: "AuthDomainTests",
            dependencies: [
                "AuthDomain",
            ],
            path: "Packages/Domain/AuthDomain/Tests"
        ),
        .target(
            name: "GoalDomain",
            path: "Packages/Domain/GoalDomain/Sources"
        ),
        .testTarget(
            name: "GoalDomainTests",
            dependencies: [
                "GoalDomain",
            ],
            path: "Packages/Domain/GoalDomain/Tests"
        ),
        .target(
            name: "InsightDomain",
            dependencies: [
                "TransactionDomain",
            ],
            path: "Packages/Domain/InsightDomain/Sources"
        ),
        .testTarget(
            name: "InsightDomainTests",
            dependencies: [
                "InsightDomain",
                "TransactionDomain",
            ],
            path: "Packages/Domain/InsightDomain/Tests"
        ),
        .target(
            name: "SubscriptionDomain",
            dependencies: [
                "TransactionDomain",
            ],
            path: "Packages/Domain/SubscriptionDomain/Sources"
        ),
        .testTarget(
            name: "SubscriptionDomainTests",
            dependencies: [
                "SubscriptionDomain",
                "TransactionDomain",
            ],
            path: "Packages/Domain/SubscriptionDomain/Tests"
        ),
        .target(
            name: "TransactionDomain",
            path: "Packages/Domain/TransactionDomain/Sources"
        ),
        .testTarget(
            name: "TransactionDomainTests",
            dependencies: [
                "TransactionDomain",
            ],
            path: "Packages/Domain/TransactionDomain/Tests"
        ),
        .target(
            name: "WellnessDomain",
            dependencies: [
                "TransactionDomain",
            ],
            path: "Packages/Domain/WellnessDomain/Sources"
        ),
        .testTarget(
            name: "WellnessDomainTests",
            dependencies: [
                "TransactionDomain",
                "WellnessDomain",
            ],
            path: "Packages/Domain/WellnessDomain/Tests"
        ),
        .target(
            name: "WealthDomain",
            path: "Packages/Domain/WealthDomain/Sources"
        ),
        .testTarget(
            name: "WealthDomainTests",
            dependencies: [
                "WealthDomain",
            ],
            path: "Packages/Domain/WealthDomain/Tests"
        ),
        .target(
            name: "DebtDomain",
            dependencies: [
                "WealthDomain",
            ],
            path: "Packages/Domain/DebtDomain/Sources"
        ),
        .testTarget(
            name: "DebtDomainTests",
            dependencies: [
                "DebtDomain",
                "WealthDomain",
            ],
            path: "Packages/Domain/DebtDomain/Tests"
        ),
        .target(
            name: "InvestmentDomain",
            dependencies: [
                "WealthDomain",
            ],
            path: "Packages/Domain/InvestmentDomain/Sources"
        ),
        .testTarget(
            name: "InvestmentDomainTests",
            dependencies: [
                "InvestmentDomain",
                "WealthDomain",
            ],
            path: "Packages/Domain/InvestmentDomain/Tests"
        ),
        .target(
            name: "PhantomExpenseDomain",
            path: "Packages/Domain/PhantomExpenseDomain/Sources"
        ),
        .testTarget(
            name: "PhantomExpenseDomainTests",
            dependencies: [
                "PhantomExpenseDomain",
            ],
            path: "Packages/Domain/PhantomExpenseDomain/Tests"
        ),
        .target(
            name: "BudgetDomain",
            dependencies: [
                "TransactionDomain",
            ],
            path: "Packages/Domain/BudgetDomain/Sources"
        ),
        .testTarget(
            name: "BudgetDomainTests",
            dependencies: [
                "BudgetDomain",
                "TransactionDomain",
            ],
            path: "Packages/Domain/BudgetDomain/Tests"
        ),
        .target(
            name: "OnboardingDomain",
            dependencies: [
                "TransactionDomain",
            ],
            path: "Packages/Domain/OnboardingDomain/Sources"
        ),
        .testTarget(
            name: "OnboardingDomainTests",
            dependencies: [
                "OnboardingDomain",
                "TransactionDomain",
            ],
            path: "Packages/Domain/OnboardingDomain/Tests"
        ),
        .target(
            name: "PersistenceKit",
            dependencies: [
                "AppearanceDomain",
                "AuthDomain",
                "BudgetDomain",
                "DebtDomain",
                "GoalDomain",
                "InvestmentDomain",
                "KasoFoundation",
                "OnboardingDomain",
                "PhantomExpenseDomain",
                "TransactionDomain",
                "WealthDomain",
                "WellnessDomain",
            ],
            path: "Packages/Data/PersistenceKit/Sources"
        ),
        .testTarget(
            name: "PersistenceKitTests",
            dependencies: [
                "AppearanceDomain",
                "BudgetDomain",
                "DebtDomain",
                "GoalDomain",
                "InvestmentDomain",
                "PersistenceKit",
                "PhantomExpenseDomain",
                "TransactionDomain",
                "WealthDomain",
                "WellnessDomain",
            ],
            path: "Packages/Data/PersistenceKit/Tests"
        ),
        .target(
            name: "AuthFeature",
            dependencies: [
                "AuthDomain",
                "KasoDesignSystem",
                tca,
            ],
            path: "Packages/Features/AuthFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "AuthFeatureTests",
            dependencies: [
                "AuthFeature",
                tca,
            ],
            path: "Packages/Features/AuthFeature/Tests"
        ),
        .target(
            name: "AppearanceFeature",
            dependencies: [
                "AppearanceDomain",
                "KasoDesignSystem",
                tca,
            ],
            path: "Packages/Features/AppearanceFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "AppearanceFeatureTests",
            dependencies: [
                "AppearanceFeature",
                tca,
            ],
            path: "Packages/Features/AppearanceFeature/Tests"
        ),
        .target(
            name: "OnboardingFeature",
            dependencies: [
                "KasoDesignSystem",
                "OnboardingDomain",
                "TransactionDomain",
                tca,
            ],
            path: "Packages/Features/OnboardingFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "OnboardingFeatureTests",
            dependencies: [
                "OnboardingDomain",
                "OnboardingFeature",
                "TransactionDomain",
                tca,
            ],
            path: "Packages/Features/OnboardingFeature/Tests"
        ),
        .target(
            name: "KasoRootFeature",
            dependencies: [
                "AppearanceDomain",
                "AppearanceFeature",
                "AuthDomain",
                "AuthFeature",
                "BudgetDomain",
                "DebtFeature",
                "GoalDomain",
                "HoursOfLifeFeature",
                "InvestmentDomain",
                "InvestmentFeature",
                "OnboardingDomain",
                "OnboardingFeature",
                "PhantomExpenseDomain",
                "PhantomExpenseFeature",
                "TransactionDomain",
                "TransactionFeature",
                "WealthDomain",
                "WealthFeature",
                "WellnessDomain",
                "WellnessFeature",
                tca,
            ],
            path: "Packages/Features/KasoRootFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "KasoRootFeatureTests",
            dependencies: [
                "BudgetDomain",
                "KasoRootFeature",
                "OnboardingDomain",
                "TransactionDomain",
                tca,
            ],
            path: "Packages/Features/KasoRootFeature/Tests"
        ),
        .target(
            name: "TransactionFeature",
            dependencies: [
                "BudgetDomain",
                "GoalDomain",
                "InsightDomain",
                "KasoDesignSystem",
                "SubscriptionDomain",
                "TransactionDomain",
                "WellnessDomain",
                tca,
            ],
            path: "Packages/Features/TransactionFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "TransactionFeatureTests",
            dependencies: [
                "GoalDomain",
                "InsightDomain",
                "SubscriptionDomain",
                "TransactionFeature",
                "WellnessDomain",
                tca,
            ],
            path: "Packages/Features/TransactionFeature/Tests"
        ),
        .target(
            name: "DebtFeature",
            dependencies: [
                "DebtDomain",
                "KasoDesignSystem",
                "WealthDomain",
                tca,
            ],
            path: "Packages/Features/DebtFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "DebtFeatureTests",
            dependencies: [
                "DebtFeature",
                tca,
            ],
            path: "Packages/Features/DebtFeature/Tests"
        ),
        .target(
            name: "InvestmentFeature",
            dependencies: [
                "InvestmentDomain",
                "KasoDesignSystem",
                "WealthDomain",
                tca,
            ],
            path: "Packages/Features/InvestmentFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "InvestmentFeatureTests",
            dependencies: [
                "InvestmentDomain",
                "InvestmentFeature",
                "WealthDomain",
                tca,
            ],
            path: "Packages/Features/InvestmentFeature/Tests"
        ),
        .target(
            name: "PhantomExpenseFeature",
            dependencies: [
                "KasoDesignSystem",
                "PhantomExpenseDomain",
                tca,
            ],
            path: "Packages/Features/PhantomExpenseFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "PhantomExpenseFeatureTests",
            dependencies: [
                "PhantomExpenseDomain",
                "PhantomExpenseFeature",
                tca,
            ],
            path: "Packages/Features/PhantomExpenseFeature/Tests"
        ),
        .target(
            name: "HoursOfLifeFeature",
            dependencies: [
                "KasoDesignSystem",
                "TransactionDomain",
                "WellnessDomain",
                tca,
            ],
            path: "Packages/Features/HoursOfLifeFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "HoursOfLifeFeatureTests",
            dependencies: [
                "HoursOfLifeFeature",
                "TransactionDomain",
                "WellnessDomain",
                tca,
            ],
            path: "Packages/Features/HoursOfLifeFeature/Tests"
        ),
        .target(
            name: "WellnessFeature",
            dependencies: [
                "HoursOfLifeFeature",
                "KasoDesignSystem",
                "PhantomExpenseFeature",
                tca,
            ],
            path: "Packages/Features/WellnessFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "WellnessFeatureTests",
            dependencies: [
                "HoursOfLifeFeature",
                "PhantomExpenseFeature",
                "WellnessFeature",
                tca,
            ],
            path: "Packages/Features/WellnessFeature/Tests"
        ),
        .target(
            name: "WealthFeature",
            dependencies: [
                "KasoDesignSystem",
                "WealthDomain",
                tca,
            ],
            path: "Packages/Features/WealthFeature/Sources",
            resources: featureResources
        ),
        .testTarget(
            name: "WealthFeatureTests",
            dependencies: [
                "WealthFeature",
                tca,
            ],
            path: "Packages/Features/WealthFeature/Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
