import ProjectDescription

let organizationName = "Kaso"
let bundlePrefix = "com.vuongnguyen.kaso"
let destinations: Destinations = .iOS
let deploymentTarget: DeploymentTargets = .iOS("17.0")
let baseSettings: SettingsDictionary = [
    "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
    "SWIFT_STRICT_CONCURRENCY": "complete",
    "SWIFT_VERSION": "6.0",
]
let projectSettings = Settings.settings(base: baseSettings)
let appSettings = Settings.settings(
    base: baseSettings.merging([
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "APPINTENTS_PACKAGE_DEPENDENCIES": "QuickEntryIntent",
    ]) { _, appValue in appValue }
)
let widgetSettings = Settings.settings(
    base: baseSettings.merging([
        "INFOPLIST_KEY_CFBundleDisplayName": "KasoWidgets",
        "INFOPLIST_KEY_NSHumanReadableCopyright": "Kaso",
    ]) { _, override in override }
)

struct ModuleSpec {
    let name: String
    let dependencies: [String]
    let testDependencies: [String]

    init(
        _ name: String,
        dependencies: [String] = [],
        testDependencies: [String]? = nil
    ) {
        self.name = name
        self.dependencies = dependencies
        self.testDependencies = testDependencies ?? dependencies
    }
}

func targetDependencies(
    _ names: [String],
    includeTCA: Bool = false
) -> [TargetDependency] {
    var dependencies = names.map { TargetDependency.target(name: $0) }
    if includeTCA {
        dependencies.append(.package(product: "ComposableArchitecture"))
    }
    return dependencies
}

func bundleId(for targetName: String) -> String {
    "\(bundlePrefix).\(targetName.lowercased())"
}

func folder(_ path: String) -> BuildableFolder {
    BuildableFolder(stringLiteral: path)
}

func moduleTarget(
    name: String,
    product: Product,
    buildableFolders: [BuildableFolder],
    dependencies: [String] = [],
    includeTCA: Bool = false
) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: product,
        bundleId: bundleId(for: name),
        deploymentTargets: deploymentTarget,
        infoPlist: .default,
        buildableFolders: buildableFolders,
        dependencies: targetDependencies(dependencies, includeTCA: includeTCA),
        settings: projectSettings
    )
}

func domainTargets(_ spec: ModuleSpec) -> [Target] {
    [
        moduleTarget(
            name: spec.name,
            product: .framework,
            buildableFolders: [folder("Packages/Domain/\(spec.name)/Sources")],
            dependencies: spec.dependencies
        ),
        moduleTarget(
            name: "\(spec.name)Tests",
            product: .unitTests,
            buildableFolders: [folder("Packages/Domain/\(spec.name)/Tests")],
            dependencies: [spec.name] + spec.testDependencies
        ),
    ]
}

func featureTargets(_ spec: ModuleSpec) -> [Target] {
    [
        moduleTarget(
            name: spec.name,
            product: .staticFramework,
            buildableFolders: [
                folder("Packages/Features/\(spec.name)/Sources"),
                folder("Packages/Features/\(spec.name)/Resources"),
            ],
            dependencies: spec.dependencies,
            includeTCA: true
        ),
        moduleTarget(
            name: "\(spec.name)Tests",
            product: .unitTests,
            buildableFolders: [folder("Packages/Features/\(spec.name)/Tests")],
            dependencies: [spec.name] + spec.testDependencies,
            includeTCA: true
        ),
    ]
}

let coreTargets: [Target] = [
    moduleTarget(
        name: "KasoFoundation",
        product: .framework,
        buildableFolders: ["Packages/Core/KasoFoundation/Sources"]
    ),
    moduleTarget(
        name: "KasoLogging",
        product: .framework,
        buildableFolders: ["Packages/Core/KasoLogging/Sources"]
    ),
    .target(
        name: "KasoWidgetShared",
        destinations: [.iPhone, .iPad, .appleWatch],
        product: .framework,
        bundleId: bundleId(for: "KasoWidgetShared"),
        deploymentTargets: .multiplatform(iOS: "17.0", watchOS: "10.0"),
        infoPlist: .default,
        buildableFolders: [folder("Packages/Core/KasoWidgetShared/Sources")],
        dependencies: [],
        settings: projectSettings
    ),
    moduleTarget(
        name: "KasoDesignSystem",
        product: .framework,
        buildableFolders: ["Packages/DesignSystem/KasoDesignSystem/Sources"]
    ),
]

let domainSpecs = [
    ModuleSpec("AppearanceDomain"),
    ModuleSpec("AuthDomain"),
    ModuleSpec("GoalDomain"),
    ModuleSpec("InsightDomain", dependencies: ["TransactionDomain"]),
    ModuleSpec("SubscriptionDomain", dependencies: ["TransactionDomain"]),
    ModuleSpec("TransactionDomain"),
    ModuleSpec("WellnessDomain", dependencies: ["TransactionDomain"]),
    ModuleSpec("WealthDomain"),
    ModuleSpec("DebtDomain", dependencies: ["WealthDomain"]),
    ModuleSpec("InvestmentDomain", dependencies: ["WealthDomain"]),
    ModuleSpec("PhantomExpenseDomain"),
    ModuleSpec("CompatibilityDomain"),
    ModuleSpec("FreelancerDomain"),
    ModuleSpec("SleepCorrelationDomain", dependencies: ["TransactionDomain"]),
    ModuleSpec("LegacyDomain"),
    ModuleSpec("BudgetDomain", dependencies: ["TransactionDomain"]),
    ModuleSpec("BudgetFlowDomain"),
    ModuleSpec("OnboardingDomain", dependencies: ["TransactionDomain"]),
    ModuleSpec(
        "GamificationDomain",
        dependencies: ["BudgetDomain", "TransactionDomain"],
        testDependencies: ["BudgetDomain", "TransactionDomain"]
    ),
    ModuleSpec("RoundUpDomain"),
    ModuleSpec("GuiltFreeBudgetDomain"),
    ModuleSpec("CoolingOffDomain"),
    ModuleSpec("MoodJournalDomain"),
    ModuleSpec("RegretScoreDomain"),
    ModuleSpec("WhatIfDomain"),
    ModuleSpec("SpendingCalendarDomain"),
    ModuleSpec("GiftTrackerDomain"),
    ModuleSpec("HuiTrackerDomain"),
    ModuleSpec("SpendingDNADomain"),
    ModuleSpec("FutureSelfDomain"),
    ModuleSpec("BNPLDomain"),
    ModuleSpec("MoneyPersonalityDomain"),
    ModuleSpec("WrappedDomain"),
    ModuleSpec("SeasonalPlannerDomain"),
    ModuleSpec("MoneyTherapistDomain"),
    ModuleSpec("CommunityChallengeDomain"),
    ModuleSpec("RemindersDomain"),
    ModuleSpec("BillSplitterDomain"),
    ModuleSpec("SmartSearchDomain"),
    ModuleSpec("SpendingMapDomain"),
    ModuleSpec("PaywallDomain"),
    ModuleSpec("CloudSyncDomain"),
]

let persistenceDependencies = [
    "AppearanceDomain", "AuthDomain", "BNPLDomain", "BudgetDomain",
    "CloudSyncDomain", "CoolingOffDomain",
    "DebtDomain", "FreelancerDomain", "GamificationDomain", "GiftTrackerDomain",
    "GoalDomain", "GuiltFreeBudgetDomain", "HuiTrackerDomain", "InvestmentDomain",
    "KasoFoundation", "LegacyDomain", "MoodJournalDomain", "OnboardingDomain",
    "PaywallDomain",
    "PhantomExpenseDomain", "RegretScoreDomain", "RoundUpDomain",
    "SpendingMapDomain",
    "TransactionDomain", "WealthDomain", "WellnessDomain",
]
let persistenceTestDependencies = [
    "AppearanceDomain", "BNPLDomain", "BudgetDomain", "CoolingOffDomain", "DebtDomain",
    "FreelancerDomain", "GamificationDomain", "GiftTrackerDomain",
    "GoalDomain", "GuiltFreeBudgetDomain",
    "InvestmentDomain", "LegacyDomain", "MoodJournalDomain",
    "PaywallDomain",
    "PersistenceKit", "PhantomExpenseDomain", "RegretScoreDomain",
    "RoundUpDomain", "SpendingMapDomain",
    "TransactionDomain", "WealthDomain", "WellnessDomain",
]

let rootFeatureDependencies = [
    "AppearanceDomain", "AppearanceFeature", "AuthDomain", "AuthFeature",
    "BenchmarkFeature", "BudgetDomain", "CoolingOffDomain", "CoolingOffFeature",
    "DebtFeature", "FinancialAssistantFeature",
    "FreelancerDomain", "FreelancerFeature", "GamificationDomain", "GamificationFeature",
    "GoalDomain", "GuiltFreeBudgetDomain", "GuiltFreeBudgetFeature",
    "HoursOfLifeFeature", "InvestmentDomain", "InvestmentFeature",
    "KasoDesignSystem", "LegacyDomain", "LegacyFeature",
    "MoodJournalDomain", "MoodJournalFeature",
    "OnboardingDomain", "OnboardingFeature",
    "PaywallDomain", "PaywallFeature",
    "PhantomExpenseDomain", "PhantomExpenseFeature",
    "RegretScoreDomain", "RegretScoreFeature",
    "RoundUpDomain", "RoundUpFeature",
    "SleepCorrelationFeature",
    "SpendingCalendarDomain", "SpendingCalendarFeature",
    "GiftTrackerDomain", "GiftTrackerFeature",
    "HuiTrackerDomain", "HuiTrackerFeature",
    "SpendingDNADomain", "SpendingDNAFeature",
    "FutureSelfDomain", "FutureSelfFeature",
    "BNPLDomain", "BNPLFeature",
    "MoneyPersonalityDomain", "MoneyPersonalityFeature",
    "WrappedDomain", "WrappedFeature",
    "SeasonalPlannerDomain", "SeasonalPlannerFeature",
    "MoneyTherapistDomain", "MoneyTherapistFeature",
    "CommunityChallengeDomain", "CommunityChallengeFeature",
    "RemindersDomain", "RemindersFeature",
    "BillSplitterDomain", "BillSplitterFeature",
    "SmartSearchDomain", "SmartSearchFeature",
    "SpendingMapDomain", "SpendingMapFeature",
    "TransactionDomain", "TransactionFeature", "WealthDomain", "WealthFeature",
    "WellnessDomain", "WellnessFeature", "WhatIfDomain", "WhatIfFeature",
]

let featureSpecs = [
    ModuleSpec("AuthFeature", dependencies: ["AuthDomain", "KasoDesignSystem"]),
    ModuleSpec("AppearanceFeature", dependencies: ["AppearanceDomain", "KasoDesignSystem"]),
    ModuleSpec(
        "BenchmarkFeature",
        dependencies: ["InsightDomain", "KasoDesignSystem", "TransactionDomain"],
        testDependencies: ["InsightDomain", "TransactionDomain"]
    ),
    ModuleSpec(
        "FinancialAssistantFeature",
        dependencies: ["InsightDomain", "KasoDesignSystem", "TransactionDomain"],
        testDependencies: ["InsightDomain", "TransactionDomain"]
    ),
    ModuleSpec(
        "OnboardingFeature",
        dependencies: ["KasoDesignSystem", "OnboardingDomain", "TransactionDomain"],
        testDependencies: ["OnboardingDomain", "TransactionDomain"]
    ),
    ModuleSpec(
        "KasoRootFeature",
        dependencies: rootFeatureDependencies,
        testDependencies: ["BudgetDomain", "OnboardingDomain", "PaywallDomain", "TransactionDomain"]
    ),
    ModuleSpec(
        "TransactionFeature",
        dependencies: [
            "BudgetDomain", "GoalDomain", "InsightDomain", "KasoDesignSystem",
            "SmartSearchDomain", "SubscriptionDomain", "TransactionDomain", "WellnessDomain",
        ],
        testDependencies: [
            "GoalDomain", "InsightDomain", "SmartSearchDomain",
            "SubscriptionDomain", "WellnessDomain",
        ]
    ),
    ModuleSpec(
        "DebtFeature",
        dependencies: ["DebtDomain", "KasoDesignSystem", "WealthDomain"]
    ),
    ModuleSpec(
        "InvestmentFeature",
        dependencies: ["InvestmentDomain", "KasoDesignSystem", "WealthDomain"],
        testDependencies: ["InvestmentDomain", "WealthDomain"]
    ),
    ModuleSpec(
        "PhantomExpenseFeature",
        dependencies: ["KasoDesignSystem", "PhantomExpenseDomain"],
        testDependencies: ["PhantomExpenseDomain"]
    ),
    ModuleSpec(
        "CompatibilityFeature",
        dependencies: ["CompatibilityDomain", "KasoDesignSystem"],
        testDependencies: ["CompatibilityDomain"]
    ),
    ModuleSpec(
        "FreelancerFeature",
        dependencies: ["FreelancerDomain", "KasoDesignSystem"],
        testDependencies: ["FreelancerDomain"]
    ),
    ModuleSpec(
        "SleepCorrelationFeature",
        dependencies: ["KasoDesignSystem", "SleepCorrelationDomain", "TransactionDomain"],
        testDependencies: ["SleepCorrelationDomain", "TransactionDomain"]
    ),
    ModuleSpec(
        "LegacyFeature",
        dependencies: ["KasoDesignSystem", "LegacyDomain"],
        testDependencies: ["LegacyDomain"]
    ),
    ModuleSpec(
        "WealthFeature",
        dependencies: ["KasoDesignSystem", "WealthDomain"]
    ),
    ModuleSpec(
        "HoursOfLifeFeature",
        dependencies: ["KasoDesignSystem", "TransactionDomain", "WellnessDomain"],
        testDependencies: ["TransactionDomain", "WellnessDomain"]
    ),
    ModuleSpec(
        "GamificationFeature",
        dependencies: [
            "BudgetDomain", "GamificationDomain", "KasoDesignSystem", "TransactionDomain",
        ],
        testDependencies: [
            "BudgetDomain", "GamificationDomain", "TransactionDomain",
        ]
    ),
    ModuleSpec(
        "RoundUpFeature",
        dependencies: ["KasoDesignSystem", "RoundUpDomain"],
        testDependencies: ["RoundUpDomain"]
    ),
    ModuleSpec(
        "GuiltFreeBudgetFeature",
        dependencies: ["GuiltFreeBudgetDomain", "KasoDesignSystem"],
        testDependencies: ["GuiltFreeBudgetDomain"]
    ),
    ModuleSpec(
        "BudgetFlowFeature",
        dependencies: ["BudgetFlowDomain", "KasoDesignSystem"],
        testDependencies: ["BudgetFlowDomain"]
    ),
    ModuleSpec(
        "CoolingOffFeature",
        dependencies: ["CoolingOffDomain", "KasoDesignSystem"],
        testDependencies: ["CoolingOffDomain"]
    ),
    ModuleSpec(
        "MoodJournalFeature",
        dependencies: ["KasoDesignSystem", "MoodJournalDomain"],
        testDependencies: ["MoodJournalDomain"]
    ),
    ModuleSpec(
        "RegretScoreFeature",
        dependencies: ["KasoDesignSystem", "RegretScoreDomain"],
        testDependencies: ["RegretScoreDomain"]
    ),
    ModuleSpec(
        "WhatIfFeature",
        dependencies: ["KasoDesignSystem", "WhatIfDomain"],
        testDependencies: ["WhatIfDomain"]
    ),
    ModuleSpec(
        "SpendingCalendarFeature",
        dependencies: ["KasoDesignSystem", "SpendingCalendarDomain"],
        testDependencies: ["SpendingCalendarDomain"]
    ),
    ModuleSpec(
        "GiftTrackerFeature",
        dependencies: ["KasoDesignSystem", "GiftTrackerDomain"],
        testDependencies: ["GiftTrackerDomain"]
    ),
    ModuleSpec(
        "BNPLFeature",
        dependencies: ["KasoDesignSystem", "BNPLDomain"],
        testDependencies: ["BNPLDomain"]
    ),
    ModuleSpec(
        "HuiTrackerFeature",
        dependencies: ["KasoDesignSystem", "HuiTrackerDomain"],
        testDependencies: ["HuiTrackerDomain"]
    ),
    ModuleSpec(
        "SpendingDNAFeature",
        dependencies: ["KasoDesignSystem", "SpendingDNADomain"],
        testDependencies: ["SpendingDNADomain"]
    ),
    ModuleSpec(
        "FutureSelfFeature",
        dependencies: ["KasoDesignSystem", "FutureSelfDomain"],
        testDependencies: ["FutureSelfDomain"]
    ),
    ModuleSpec(
        "MoneyPersonalityFeature",
        dependencies: ["KasoDesignSystem", "MoneyPersonalityDomain"],
        testDependencies: ["MoneyPersonalityDomain"]
    ),
    ModuleSpec(
        "WrappedFeature",
        dependencies: ["KasoDesignSystem", "WrappedDomain"],
        testDependencies: ["WrappedDomain"]
    ),
    ModuleSpec(
        "SeasonalPlannerFeature",
        dependencies: ["KasoDesignSystem", "SeasonalPlannerDomain"],
        testDependencies: ["SeasonalPlannerDomain"]
    ),
    ModuleSpec(
        "MoneyTherapistFeature",
        dependencies: ["KasoDesignSystem", "MoneyTherapistDomain"],
        testDependencies: ["MoneyTherapistDomain"]
    ),
    ModuleSpec(
        "CommunityChallengeFeature",
        dependencies: ["KasoDesignSystem", "CommunityChallengeDomain"],
        testDependencies: ["CommunityChallengeDomain"]
    ),
    ModuleSpec(
        "RemindersFeature",
        dependencies: ["KasoDesignSystem", "RemindersDomain"],
        testDependencies: ["RemindersDomain"]
    ),
    ModuleSpec(
        "BillSplitterFeature",
        dependencies: ["KasoDesignSystem", "BillSplitterDomain"],
        testDependencies: ["BillSplitterDomain"]
    ),
    ModuleSpec(
        "SmartSearchFeature",
        dependencies: ["KasoDesignSystem", "SmartSearchDomain"],
        testDependencies: ["SmartSearchDomain"]
    ),
    ModuleSpec(
        "SpendingMapFeature",
        dependencies: ["KasoDesignSystem", "SpendingMapDomain"],
        testDependencies: ["SpendingMapDomain"]
    ),
    ModuleSpec(
        "PaywallFeature",
        dependencies: ["KasoDesignSystem", "PaywallDomain"],
        testDependencies: ["PaywallDomain"]
    ),
    ModuleSpec(
        "CloudSyncFeature",
        dependencies: ["KasoDesignSystem", "CloudSyncDomain"],
        testDependencies: ["CloudSyncDomain"]
    ),
    ModuleSpec(
        "WellnessFeature",
        dependencies: [
            "BNPLFeature", "CloudSyncFeature", "CompatibilityFeature", "CoolingOffFeature", "FreelancerFeature",
            "GamificationFeature", "GiftTrackerFeature", "GuiltFreeBudgetFeature",
            "HoursOfLifeFeature", "HuiTrackerFeature", "SpendingDNAFeature", "FutureSelfFeature",
            "KasoDesignSystem", "LegacyFeature",
            "BillSplitterFeature",
            "CommunityChallengeFeature",
            "MoneyPersonalityFeature", "MoneyTherapistFeature",
            "MoodJournalFeature", "PhantomExpenseFeature",
            "RegretScoreFeature", "RemindersFeature",
            "RoundUpFeature", "SeasonalPlannerFeature",
            "SleepCorrelationFeature", "SmartSearchFeature",
            "SpendingCalendarFeature", "SpendingMapFeature",
            "WhatIfFeature", "WrappedFeature",
        ],
        testDependencies: [
            "BNPLFeature", "BillSplitterFeature", "CloudSyncFeature",
            "CommunityChallengeFeature",
            "CompatibilityFeature", "CoolingOffFeature", "FreelancerFeature",
            "GamificationFeature", "GiftTrackerFeature", "GuiltFreeBudgetFeature",
            "HoursOfLifeFeature", "HuiTrackerFeature", "SpendingDNAFeature", "FutureSelfFeature",
            "LegacyFeature",
            "MoneyPersonalityFeature", "MoneyTherapistFeature",
            "MoodJournalFeature", "PhantomExpenseFeature",
            "RegretScoreFeature", "RemindersFeature",
            "RoundUpFeature", "SeasonalPlannerFeature",
            "SleepCorrelationFeature", "SmartSearchFeature",
            "SpendingCalendarFeature", "SpendingMapFeature",
            "WhatIfFeature", "WrappedFeature",
        ]
    ),
]

let appTarget = Target.target(
    name: "Kaso",
    destinations: destinations,
    product: .app,
    bundleId: bundlePrefix,
    deploymentTargets: deploymentTarget,
    infoPlist: .extendingDefault(
        with: [
            "CFBundleDisplayName": .string("Kaso"),
            "NSMicrophoneUsageDescription": .string(
                "Kaso dùng microphone để nhập giao dịch bằng giọng nói khi bạn bấm nút ghi âm."
            ),
            "NSSpeechRecognitionUsageDescription": .string(
                "Kaso dùng nhận diện giọng nói trên thiết bị để chuyển lời nói "
                + "thành giao dịch nháp."
            ),
            "NSHealthShareUsageDescription": .string(
                "Kaso đọc dữ liệu giấc ngủ từ HealthKit để phân tích tương quan "
                + "với chi tiêu ngay trên thiết bị."
            ),
            "NSSupportsLiveActivities": .boolean(true),
            "UILaunchScreen": .dictionary([
                "UIColorName": .string(""),
                "UIImageName": .string(""),
            ]),
        ]
    ),
    buildableFolders: [
        "App/Sources",
        "App/Resources",
    ],
    entitlements: .file(path: "App/Entitlements/Kaso.entitlements"),
    dependencies: targetDependencies([
        "BenchmarkFeature", "DebtFeature", "FinancialAssistantFeature", "FreelancerFeature",
        "GamificationFeature", "HoursOfLifeFeature", "InvestmentFeature", "KasoRootFeature",
        "KasoWidgetShared", "LegacyFeature", "PaywallDomain", "PaywallFeature",
        "PersistenceKit", "QuickEntryIntent",
        "SleepCorrelationDomain", "SleepCorrelationFeature",
    ]) + [.target(name: "KasoWidgets"), .target(name: "KasoWatchApp")],
    settings: appSettings
)

let watchTarget = Target.target(
    name: "KasoWatchApp",
    destinations: [.appleWatch],
    product: .app,
    bundleId: "\(bundlePrefix).watchkitapp",
    deploymentTargets: .watchOS("10.0"),
    infoPlist: .extendingDefault(
        with: [
            "CFBundleDisplayName": .string("Kaso"),
            "WKApplication": .boolean(true),
            "WKWatchOnly": .boolean(false),
            "WKCompanionAppBundleIdentifier": .string(bundlePrefix),
        ]
    ),
    sources: "KasoWatchAppTarget/Sources/**",
    resources: "KasoWatchAppTarget/Resources/**",
    entitlements: .file(path: "KasoWatchAppTarget/Entitlements/KasoWatchApp.entitlements"),
    dependencies: [.target(name: "KasoWidgetShared")],
    settings: projectSettings
)

let widgetTarget = Target.target(
    name: "KasoWidgets",
    destinations: destinations,
    product: .appExtension,
    bundleId: "\(bundlePrefix).widgets",
    deploymentTargets: deploymentTarget,
    infoPlist: .extendingDefault(
        with: [
            "CFBundleDisplayName": .string("Kaso Widgets"),
            "NSExtension": .dictionary([
                "NSExtensionPointIdentifier": .string("com.apple.widgetkit-extension"),
            ]),
        ]
    ),
    sources: "KasoWidgetsTarget/Sources/**",
    resources: "KasoWidgetsTarget/Resources/**",
    entitlements: .file(path: "KasoWidgetsTarget/Entitlements/KasoWidgets.entitlements"),
    dependencies: [.target(name: "KasoWidgetShared")],
    settings: projectSettings
)

let dataTargets = [
    moduleTarget(
        name: "PersistenceKit",
        product: .framework,
        buildableFolders: ["Packages/Data/PersistenceKit/Sources"],
        dependencies: persistenceDependencies
    ),
    moduleTarget(
        name: "PersistenceKitTests",
        product: .unitTests,
        buildableFolders: ["Packages/Data/PersistenceKit/Tests"],
        dependencies: persistenceTestDependencies
    ),
]

let quickEntryIntentTargets: [Target] = [
    moduleTarget(
        name: "QuickEntryIntent",
        product: .staticFramework,
        buildableFolders: ["Packages/Features/QuickEntryIntent/Sources"],
        dependencies: ["PersistenceKit", "TransactionDomain"]
    ),
    moduleTarget(
        name: "QuickEntryIntentTests",
        product: .unitTests,
        buildableFolders: ["Packages/Features/QuickEntryIntent/Tests"],
        dependencies: ["QuickEntryIntent", "PersistenceKit", "TransactionDomain"]
    ),
]

let project = Project(
    name: "Kaso",
    organizationName: organizationName,
    packages: [
        .remote(
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            requirement: .upToNextMajor(from: "1.0.0")
        ),
    ],
    settings: projectSettings,
    targets: [appTarget, widgetTarget, watchTarget]
        + coreTargets
        + domainSpecs.flatMap(domainTargets)
        + dataTargets
        + featureSpecs.flatMap(featureTargets)
        + quickEntryIntentTargets
)
