// swift-tools-version: 6.0

import PackageDescription

let tca: Target.Dependency = .product(
    name: "ComposableArchitecture",
    package: "swift-composable-architecture"
)
let featureResources: [Resource] = [.process("../Resources")]
let libraryProductNames = [
    "KasoFoundation", "KasoLogging", "KasoWidgetShared", "KasoDesignSystem",
    "AppearanceDomain", "AuthDomain", "GoalDomain", "InsightDomain",
    "SubscriptionDomain", "TransactionDomain", "WellnessDomain",
    "WealthDomain", "DebtDomain", "InvestmentDomain",
    "PhantomExpenseDomain", "CompatibilityDomain", "FreelancerDomain",
    "SleepCorrelationDomain", "LegacyDomain", "BudgetDomain", "BudgetFlowDomain",
    "OnboardingDomain", "RoundUpDomain", "GuiltFreeBudgetDomain",
    "CoolingOffDomain", "MoodJournalDomain", "RegretScoreDomain",
    "WhatIfDomain", "SpendingCalendarDomain", "GiftTrackerDomain", "BNPLDomain",
    "HuiTrackerDomain", "SpendingDNADomain", "FutureSelfDomain",
    "MoneyPersonalityDomain", "WrappedDomain",
    "SeasonalPlannerDomain", "MoneyTherapistDomain",
    "CommunityChallengeDomain", "RemindersDomain", "BillSplitterDomain",
    "SmartSearchDomain", "SpendingMapDomain", "PaywallDomain", "CloudSyncDomain",
    "PersistenceKit", "AppearanceFeature",
    "AuthFeature", "BenchmarkFeature", "OnboardingFeature", "KasoRootFeature",
    "FinancialAssistantFeature", "TransactionFeature", "WealthFeature", "DebtFeature",
    "InvestmentFeature", "PhantomExpenseFeature", "CompatibilityFeature",
    "FreelancerFeature", "SleepCorrelationFeature", "LegacyFeature",
    "HoursOfLifeFeature", "RoundUpFeature", "GuiltFreeBudgetFeature", "BudgetFlowFeature",
    "CoolingOffFeature", "MoodJournalFeature", "RegretScoreFeature",
    "WhatIfFeature", "SpendingCalendarFeature", "GiftTrackerFeature", "BNPLFeature",
    "HuiTrackerFeature", "SpendingDNAFeature", "FutureSelfFeature",
    "MoneyPersonalityFeature", "WrappedFeature",
    "SeasonalPlannerFeature", "MoneyTherapistFeature",
    "CommunityChallengeFeature", "RemindersFeature", "BillSplitterFeature",
    "SmartSearchFeature", "SpendingMapFeature", "PaywallFeature", "CloudSyncFeature",
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
    "AppearanceDomain", "AuthDomain", "BNPLDomain", "BudgetDomain", "CloudSyncDomain", "CoolingOffDomain",
    "DebtDomain", "FreelancerDomain", "GiftTrackerDomain", "GoalDomain", "GuiltFreeBudgetDomain",
    "HuiTrackerDomain", "InvestmentDomain", "KasoFoundation",
    "LegacyDomain", "MoodJournalDomain", "OnboardingDomain", "PaywallDomain", "PhantomExpenseDomain",
    "RegretScoreDomain", "RoundUpDomain", "SpendingMapDomain", "TransactionDomain", "WealthDomain",
    "WellnessDomain",
]
let persistenceTestDependencies: [Target.Dependency] = [
    "AppearanceDomain", "BudgetDomain", "CoolingOffDomain", "DebtDomain", "GoalDomain",
    "FreelancerDomain", "GuiltFreeBudgetDomain", "InvestmentDomain", "LegacyDomain",
    "MoodJournalDomain", "PaywallDomain",
    "PersistenceKit", "PhantomExpenseDomain", "RegretScoreDomain",
    "RoundUpDomain", "SpendingMapDomain", "TransactionDomain", "WealthDomain", "WellnessDomain",
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
    "PaywallDomain", "PaywallFeature",
    "PhantomExpenseDomain", "PhantomExpenseFeature", "RegretScoreDomain", "RegretScoreFeature",
    "RoundUpDomain", "RoundUpFeature", "SpendingCalendarDomain", "SpendingCalendarFeature",
    "GiftTrackerDomain", "GiftTrackerFeature", "BNPLDomain", "BNPLFeature",
    "HuiTrackerDomain", "HuiTrackerFeature",
    "SpendingDNADomain", "SpendingDNAFeature",
    "FutureSelfDomain", "FutureSelfFeature",
    "MoneyPersonalityDomain", "MoneyPersonalityFeature",
    "WrappedDomain", "WrappedFeature",
    "SeasonalPlannerDomain", "SeasonalPlannerFeature",
    "TransactionDomain",
    "SleepCorrelationFeature", "SpendingMapDomain", "SpendingMapFeature",
    "TransactionFeature", "WealthDomain",
    "WealthFeature", "WellnessDomain", "WellnessFeature", "WhatIfDomain", "WhatIfFeature",
    tca,
]
let transactionFeatureDependencies: [Target.Dependency] = [
    "BudgetDomain", "GoalDomain", "InsightDomain", "KasoDesignSystem",
    "SmartSearchDomain", "SubscriptionDomain", "TransactionDomain", "WellnessDomain", tca,
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
                "HoursOfLifeFeature", "InvestmentFeature", "KasoRootFeature", "KasoWidgetShared",
                "LegacyFeature", "PaywallDomain", "PaywallFeature",
                "PersistenceKit", "QuickEntryIntent", "SleepCorrelationDomain",
                "SleepCorrelationFeature",
            ],
            path: "App/Sources",
            resources: featureResources
        ),
        sourceTarget("KasoFoundation", path: "Packages/Core/KasoFoundation/Sources"),
        sourceTarget("KasoLogging", path: "Packages/Core/KasoLogging/Sources"),
        sourceTarget("KasoWidgetShared", path: "Packages/Core/KasoWidgetShared/Sources"),
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
        sourceTarget(
            "BudgetFlowDomain",
            path: "Packages/Domain/BudgetFlowDomain/Sources"
        ),
        testTarget(
            "BudgetFlowDomainTests",
            ["BudgetFlowDomain"],
            path: "Packages/Domain/BudgetFlowDomain/Tests"
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
        sourceTarget("GiftTrackerDomain", path: "Packages/Domain/GiftTrackerDomain/Sources"),
        testTarget(
            "GiftTrackerDomainTests",
            ["GiftTrackerDomain"],
            path: "Packages/Domain/GiftTrackerDomain/Tests"
        ),
        sourceTarget("BNPLDomain", path: "Packages/Domain/BNPLDomain/Sources"),
        testTarget(
            "BNPLDomainTests",
            ["BNPLDomain"],
            path: "Packages/Domain/BNPLDomain/Tests"
        ),
        sourceTarget("HuiTrackerDomain", path: "Packages/Domain/HuiTrackerDomain/Sources"),
        testTarget(
            "HuiTrackerDomainTests",
            ["HuiTrackerDomain"],
            path: "Packages/Domain/HuiTrackerDomain/Tests"
        ),
        sourceTarget("SpendingDNADomain", path: "Packages/Domain/SpendingDNADomain/Sources"),
        testTarget(
            "SpendingDNADomainTests",
            ["SpendingDNADomain"],
            path: "Packages/Domain/SpendingDNADomain/Tests"
        ),
        sourceTarget("FutureSelfDomain", path: "Packages/Domain/FutureSelfDomain/Sources"),
        testTarget(
            "FutureSelfDomainTests",
            ["FutureSelfDomain"],
            path: "Packages/Domain/FutureSelfDomain/Tests"
        ),
        sourceTarget("MoneyPersonalityDomain", path: "Packages/Domain/MoneyPersonalityDomain/Sources"),
        testTarget(
            "MoneyPersonalityDomainTests",
            ["MoneyPersonalityDomain"],
            path: "Packages/Domain/MoneyPersonalityDomain/Tests"
        ),
        sourceTarget("WrappedDomain", path: "Packages/Domain/WrappedDomain/Sources"),
        testTarget(
            "WrappedDomainTests",
            ["WrappedDomain"],
            path: "Packages/Domain/WrappedDomain/Tests"
        ),
        sourceTarget("SeasonalPlannerDomain", path: "Packages/Domain/SeasonalPlannerDomain/Sources"),
        testTarget(
            "SeasonalPlannerDomainTests",
            ["SeasonalPlannerDomain"],
            path: "Packages/Domain/SeasonalPlannerDomain/Tests"
        ),
        sourceTarget("MoneyTherapistDomain", path: "Packages/Domain/MoneyTherapistDomain/Sources"),
        testTarget(
            "MoneyTherapistDomainTests",
            ["MoneyTherapistDomain"],
            path: "Packages/Domain/MoneyTherapistDomain/Tests"
        ),
        sourceTarget("CommunityChallengeDomain", path: "Packages/Domain/CommunityChallengeDomain/Sources"),
        testTarget(
            "CommunityChallengeDomainTests",
            ["CommunityChallengeDomain"],
            path: "Packages/Domain/CommunityChallengeDomain/Tests"
        ),
        sourceTarget("RemindersDomain", path: "Packages/Domain/RemindersDomain/Sources"),
        testTarget(
            "RemindersDomainTests",
            ["RemindersDomain"],
            path: "Packages/Domain/RemindersDomain/Tests"
        ),
        sourceTarget("BillSplitterDomain", path: "Packages/Domain/BillSplitterDomain/Sources"),
        testTarget(
            "BillSplitterDomainTests",
            ["BillSplitterDomain"],
            path: "Packages/Domain/BillSplitterDomain/Tests"
        ),
        sourceTarget("SmartSearchDomain", path: "Packages/Domain/SmartSearchDomain/Sources"),
        testTarget(
            "SmartSearchDomainTests",
            ["SmartSearchDomain"],
            path: "Packages/Domain/SmartSearchDomain/Tests"
        ),
        sourceTarget("SpendingMapDomain", path: "Packages/Domain/SpendingMapDomain/Sources"),
        testTarget(
            "SpendingMapDomainTests",
            ["SpendingMapDomain"],
            path: "Packages/Domain/SpendingMapDomain/Tests"
        ),
        sourceTarget("PaywallDomain", path: "Packages/Domain/PaywallDomain/Sources"),
        testTarget(
            "PaywallDomainTests",
            ["PaywallDomain"],
            path: "Packages/Domain/PaywallDomain/Tests"
        ),
        sourceTarget("CloudSyncDomain", path: "Packages/Domain/CloudSyncDomain/Sources"),
        testTarget(
            "CloudSyncDomainTests",
            ["CloudSyncDomain"],
            path: "Packages/Domain/CloudSyncDomain/Tests"
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
            ["BudgetDomain", "KasoRootFeature", "OnboardingDomain", "PaywallDomain", "TransactionDomain", tca],
            path: "Packages/Features/KasoRootFeature/Tests"
        ),
        featureTarget(
            "TransactionFeature",
            transactionFeatureDependencies,
            path: "Packages/Features/TransactionFeature/Sources"
        ),
        testTarget(
            "TransactionFeatureTests",
            ["GoalDomain", "InsightDomain", "SmartSearchDomain", "SubscriptionDomain", "TransactionFeature", "WellnessDomain", tca],
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
        .target(
            name: "BudgetFlowFeature",
            dependencies: ["BudgetFlowDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/BudgetFlowFeature/Sources",
            resources: [
                .process("../Resources"),
                .process("Shaders/budget_flow_ribbon.metal"),
            ]
        ),
        testTarget(
            "BudgetFlowFeatureTests",
            ["BudgetFlowDomain", "BudgetFlowFeature", tca],
            path: "Packages/Features/BudgetFlowFeature/Tests"
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
            "GiftTrackerFeature",
            ["GiftTrackerDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/GiftTrackerFeature/Sources"
        ),
        testTarget(
            "GiftTrackerFeatureTests",
            ["GiftTrackerDomain", "GiftTrackerFeature", tca],
            path: "Packages/Features/GiftTrackerFeature/Tests"
        ),
        featureTarget(
            "BNPLFeature",
            ["BNPLDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/BNPLFeature/Sources"
        ),
        testTarget(
            "BNPLFeatureTests",
            ["BNPLDomain", "BNPLFeature", tca],
            path: "Packages/Features/BNPLFeature/Tests"
        ),
        featureTarget(
            "HuiTrackerFeature",
            ["HuiTrackerDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/HuiTrackerFeature/Sources"
        ),
        testTarget(
            "HuiTrackerFeatureTests",
            ["HuiTrackerDomain", "HuiTrackerFeature", tca],
            path: "Packages/Features/HuiTrackerFeature/Tests"
        ),
        featureTarget(
            "SpendingDNAFeature",
            ["SpendingDNADomain", "KasoDesignSystem", tca],
            path: "Packages/Features/SpendingDNAFeature/Sources"
        ),
        testTarget(
            "SpendingDNAFeatureTests",
            ["SpendingDNADomain", "SpendingDNAFeature", tca],
            path: "Packages/Features/SpendingDNAFeature/Tests"
        ),
        featureTarget(
            "FutureSelfFeature",
            ["FutureSelfDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/FutureSelfFeature/Sources"
        ),
        testTarget(
            "FutureSelfFeatureTests",
            ["FutureSelfDomain", "FutureSelfFeature", tca],
            path: "Packages/Features/FutureSelfFeature/Tests"
        ),
        featureTarget(
            "MoneyPersonalityFeature",
            ["MoneyPersonalityDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/MoneyPersonalityFeature/Sources"
        ),
        testTarget(
            "MoneyPersonalityFeatureTests",
            ["MoneyPersonalityDomain", "MoneyPersonalityFeature", tca],
            path: "Packages/Features/MoneyPersonalityFeature/Tests"
        ),
        featureTarget(
            "WrappedFeature",
            ["WrappedDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/WrappedFeature/Sources"
        ),
        testTarget(
            "WrappedFeatureTests",
            ["WrappedDomain", "WrappedFeature", tca],
            path: "Packages/Features/WrappedFeature/Tests"
        ),
        featureTarget(
            "SeasonalPlannerFeature",
            ["SeasonalPlannerDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/SeasonalPlannerFeature/Sources"
        ),
        testTarget(
            "SeasonalPlannerFeatureTests",
            ["SeasonalPlannerDomain", "SeasonalPlannerFeature", tca],
            path: "Packages/Features/SeasonalPlannerFeature/Tests"
        ),
        featureTarget(
            "MoneyTherapistFeature",
            ["MoneyTherapistDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/MoneyTherapistFeature/Sources"
        ),
        testTarget(
            "MoneyTherapistFeatureTests",
            ["MoneyTherapistDomain", "MoneyTherapistFeature", tca],
            path: "Packages/Features/MoneyTherapistFeature/Tests"
        ),
        featureTarget(
            "CommunityChallengeFeature",
            ["CommunityChallengeDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/CommunityChallengeFeature/Sources"
        ),
        testTarget(
            "CommunityChallengeFeatureTests",
            ["CommunityChallengeDomain", "CommunityChallengeFeature", tca],
            path: "Packages/Features/CommunityChallengeFeature/Tests"
        ),
        featureTarget(
            "RemindersFeature",
            ["RemindersDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/RemindersFeature/Sources"
        ),
        testTarget(
            "RemindersFeatureTests",
            ["RemindersDomain", "RemindersFeature", tca],
            path: "Packages/Features/RemindersFeature/Tests"
        ),
        featureTarget(
            "BillSplitterFeature",
            ["BillSplitterDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/BillSplitterFeature/Sources"
        ),
        testTarget(
            "BillSplitterFeatureTests",
            ["BillSplitterDomain", "BillSplitterFeature", tca],
            path: "Packages/Features/BillSplitterFeature/Tests"
        ),
        featureTarget(
            "SmartSearchFeature",
            ["SmartSearchDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/SmartSearchFeature/Sources"
        ),
        testTarget(
            "SmartSearchFeatureTests",
            ["SmartSearchDomain", "SmartSearchFeature", tca],
            path: "Packages/Features/SmartSearchFeature/Tests"
        ),
        featureTarget(
            "SpendingMapFeature",
            ["SpendingMapDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/SpendingMapFeature/Sources"
        ),
        testTarget(
            "SpendingMapFeatureTests",
            ["SpendingMapDomain", "SpendingMapFeature", tca],
            path: "Packages/Features/SpendingMapFeature/Tests"
        ),
        featureTarget(
            "PaywallFeature",
            ["PaywallDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/PaywallFeature/Sources"
        ),
        testTarget(
            "PaywallFeatureTests",
            ["PaywallDomain", "PaywallFeature", tca],
            path: "Packages/Features/PaywallFeature/Tests"
        ),
        featureTarget(
            "CloudSyncFeature",
            ["CloudSyncDomain", "KasoDesignSystem", tca],
            path: "Packages/Features/CloudSyncFeature/Sources"
        ),
        testTarget(
            "CloudSyncFeatureTests",
            ["CloudSyncDomain", "CloudSyncFeature", tca],
            path: "Packages/Features/CloudSyncFeature/Tests"
        ),
        featureTarget(
            "WellnessFeature",
            [
                "BNPLFeature", "CloudSyncFeature",
                "CompatibilityFeature", "CoolingOffFeature", "FreelancerFeature",
                "GiftTrackerFeature", "GuiltFreeBudgetFeature", "HoursOfLifeFeature",
                "HuiTrackerFeature", "SpendingDNAFeature", "FutureSelfFeature",
                "KasoDesignSystem", "LegacyFeature", "MoneyPersonalityFeature",
                "MoodJournalFeature",
                "BillSplitterFeature",
                "CommunityChallengeFeature",
                "MoneyTherapistFeature",
                "PhantomExpenseFeature", "RegretScoreFeature", "RemindersFeature",
                "RoundUpFeature", "SeasonalPlannerFeature", "SleepCorrelationFeature",
                "SmartSearchFeature",
                "SpendingCalendarFeature", "SpendingMapFeature",
                "WhatIfFeature", "WrappedFeature", tca,
            ],
            path: "Packages/Features/WellnessFeature/Sources"
        ),
        testTarget(
            "WellnessFeatureTests",
            [
                "BNPLFeature", "BillSplitterFeature", "CloudSyncFeature",
                "CommunityChallengeFeature", "CompatibilityFeature",
                "CoolingOffFeature", "FreelancerFeature",
                "GiftTrackerFeature", "GuiltFreeBudgetFeature", "HoursOfLifeFeature",
                "HuiTrackerFeature", "SpendingDNAFeature", "FutureSelfFeature",
                "LegacyFeature", "MoneyPersonalityFeature", "MoodJournalFeature",
                "MoneyTherapistFeature",
                "PhantomExpenseFeature",
                "RegretScoreFeature", "RemindersFeature",
                "RoundUpFeature", "SeasonalPlannerFeature",
                "SleepCorrelationFeature", "SmartSearchFeature",
                "SpendingCalendarFeature", "SpendingMapFeature",
                "WellnessFeature", "WhatIfFeature", "WrappedFeature", tca,
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
