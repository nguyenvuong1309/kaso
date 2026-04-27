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
    ]) { _, appValue in appValue }
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
    ModuleSpec("OnboardingDomain", dependencies: ["TransactionDomain"]),
]

let persistenceDependencies = [
    "AppearanceDomain", "AuthDomain", "BudgetDomain", "DebtDomain",
    "FreelancerDomain", "GoalDomain", "InvestmentDomain", "KasoFoundation",
    "LegacyDomain", "OnboardingDomain", "PhantomExpenseDomain",
    "TransactionDomain", "WealthDomain", "WellnessDomain",
]
let persistenceTestDependencies = [
    "AppearanceDomain", "BudgetDomain", "DebtDomain", "FreelancerDomain",
    "GoalDomain", "InvestmentDomain", "LegacyDomain", "PersistenceKit",
    "PhantomExpenseDomain", "TransactionDomain", "WealthDomain", "WellnessDomain",
]

let rootFeatureDependencies = [
    "AppearanceDomain", "AppearanceFeature", "AuthDomain", "AuthFeature",
    "BenchmarkFeature", "BudgetDomain", "DebtFeature", "FinancialAssistantFeature", "FreelancerDomain",
    "FreelancerFeature", "GoalDomain", "HoursOfLifeFeature", "InvestmentDomain",
    "InvestmentFeature", "KasoDesignSystem", "LegacyDomain", "LegacyFeature",
    "OnboardingDomain", "OnboardingFeature",
    "PhantomExpenseDomain", "PhantomExpenseFeature", "SleepCorrelationFeature",
    "TransactionDomain", "TransactionFeature", "WealthDomain", "WealthFeature",
    "WellnessDomain", "WellnessFeature",
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
        testDependencies: ["BudgetDomain", "OnboardingDomain", "TransactionDomain"]
    ),
    ModuleSpec(
        "TransactionFeature",
        dependencies: [
            "BudgetDomain", "GoalDomain", "InsightDomain", "KasoDesignSystem",
            "SubscriptionDomain", "TransactionDomain", "WellnessDomain",
        ],
        testDependencies: ["GoalDomain", "InsightDomain", "SubscriptionDomain", "WellnessDomain"]
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
        "WellnessFeature",
        dependencies: [
            "CompatibilityFeature", "FreelancerFeature", "HoursOfLifeFeature",
            "KasoDesignSystem", "LegacyFeature", "PhantomExpenseFeature",
            "SleepCorrelationFeature",
        ],
        testDependencies: [
            "CompatibilityFeature", "FreelancerFeature", "HoursOfLifeFeature",
            "LegacyFeature", "PhantomExpenseFeature", "SleepCorrelationFeature",
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
        "HoursOfLifeFeature", "InvestmentFeature", "KasoRootFeature",
        "LegacyFeature", "PersistenceKit", "SleepCorrelationDomain",
        "SleepCorrelationFeature",
    ]),
    settings: appSettings
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
    targets: [appTarget]
        + coreTargets
        + domainSpecs.flatMap(domainTargets)
        + dataTargets
        + featureSpecs.flatMap(featureTargets)
)
