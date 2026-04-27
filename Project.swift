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
    ]) { _, appValue in
        appValue
    }
)

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
    targets: [
        .target(
            name: "Kaso",
            destinations: destinations,
            product: .app,
            bundleId: bundlePrefix,
            deploymentTargets: deploymentTarget,
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "Kaso",
                    "NSMicrophoneUsageDescription": "Kaso dùng microphone để nhập giao dịch bằng giọng nói khi bạn bấm nút ghi âm.",
                    "NSSpeechRecognitionUsageDescription": "Kaso dùng nhận diện giọng nói trên thiết bị để chuyển lời nói thành giao dịch nháp.",
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "App/Sources",
                "App/Resources",
            ],
            entitlements: .file(path: "App/Entitlements/Kaso.entitlements"),
            dependencies: [
                .target(name: "DebtFeature"),
                .target(name: "HoursOfLifeFeature"),
                .target(name: "InvestmentFeature"),
                .target(name: "KasoRootFeature"),
                .target(name: "PersistenceKit"),
            ],
            settings: appSettings
        ),
        .target(
            name: "KasoFoundation",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).foundation",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Core/KasoFoundation/Sources",
            ],
            settings: projectSettings
        ),
        .target(
            name: "KasoLogging",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).logging",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Core/KasoLogging/Sources",
            ],
            settings: projectSettings
        ),
        .target(
            name: "KasoDesignSystem",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).design-system",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/DesignSystem/KasoDesignSystem/Sources",
            ],
            settings: projectSettings
        ),
        .target(
            name: "AppearanceDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).appearance-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/AppearanceDomain/Sources",
            ],
            settings: projectSettings
        ),
        .target(
            name: "AppearanceDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).appearance-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/AppearanceDomain/Tests",
            ],
            dependencies: [
                .target(name: "AppearanceDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "TransactionDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).transaction-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/TransactionDomain/Sources",
            ],
            settings: projectSettings
        ),
        .target(
            name: "AuthDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).auth-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/AuthDomain/Sources",
            ],
            settings: projectSettings
        ),
        .target(
            name: "AuthDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).auth-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/AuthDomain/Tests",
            ],
            dependencies: [
                .target(name: "AuthDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "GoalDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).goal-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/GoalDomain/Sources",
            ],
            settings: projectSettings
        ),
        .target(
            name: "GoalDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).goal-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/GoalDomain/Tests",
            ],
            dependencies: [
                .target(name: "GoalDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "InsightDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).insight-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/InsightDomain/Sources",
            ],
            dependencies: [
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "InsightDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).insight-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/InsightDomain/Tests",
            ],
            dependencies: [
                .target(name: "InsightDomain"),
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "SubscriptionDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).subscription-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/SubscriptionDomain/Sources",
            ],
            dependencies: [
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "SubscriptionDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).subscription-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/SubscriptionDomain/Tests",
            ],
            dependencies: [
                .target(name: "SubscriptionDomain"),
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "TransactionDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).transaction-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/TransactionDomain/Tests",
            ],
            dependencies: [
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "WellnessDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).wellness-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/WellnessDomain/Sources",
            ],
            dependencies: [
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "WellnessDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).wellness-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/WellnessDomain/Tests",
            ],
            dependencies: [
                .target(name: "TransactionDomain"),
                .target(name: "WellnessDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "WealthDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).wealth-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/WealthDomain/Sources",
            ],
            settings: projectSettings
        ),
        .target(
            name: "WealthDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).wealth-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/WealthDomain/Tests",
            ],
            dependencies: [
                .target(name: "WealthDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "DebtDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).debt-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/DebtDomain/Sources",
            ],
            dependencies: [
                .target(name: "WealthDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "DebtDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).debt-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/DebtDomain/Tests",
            ],
            dependencies: [
                .target(name: "DebtDomain"),
                .target(name: "WealthDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "InvestmentDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).investment-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/InvestmentDomain/Sources",
            ],
            dependencies: [
                .target(name: "WealthDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "InvestmentDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).investment-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/InvestmentDomain/Tests",
            ],
            dependencies: [
                .target(name: "InvestmentDomain"),
                .target(name: "WealthDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "PhantomExpenseDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).phantom-expense-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/PhantomExpenseDomain/Sources",
            ],
            settings: projectSettings
        ),
        .target(
            name: "PhantomExpenseDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).phantom-expense-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/PhantomExpenseDomain/Tests",
            ],
            dependencies: [
                .target(name: "PhantomExpenseDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "BudgetDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).budget-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/BudgetDomain/Sources",
            ],
            dependencies: [
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "BudgetDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).budget-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/BudgetDomain/Tests",
            ],
            dependencies: [
                .target(name: "BudgetDomain"),
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "OnboardingDomain",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).onboarding-domain",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/OnboardingDomain/Sources",
            ],
            dependencies: [
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "OnboardingDomainTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).onboarding-domain-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Domain/OnboardingDomain/Tests",
            ],
            dependencies: [
                .target(name: "OnboardingDomain"),
                .target(name: "TransactionDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "PersistenceKit",
            destinations: destinations,
            product: .framework,
            bundleId: "\(bundlePrefix).persistence-kit",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Data/PersistenceKit/Sources",
            ],
            dependencies: [
                .target(name: "AppearanceDomain"),
                .target(name: "AuthDomain"),
                .target(name: "BudgetDomain"),
                .target(name: "DebtDomain"),
                .target(name: "GoalDomain"),
                .target(name: "InvestmentDomain"),
                .target(name: "KasoFoundation"),
                .target(name: "OnboardingDomain"),
                .target(name: "PhantomExpenseDomain"),
                .target(name: "TransactionDomain"),
                .target(name: "WealthDomain"),
                .target(name: "WellnessDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "PersistenceKitTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).persistence-kit-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Data/PersistenceKit/Tests",
            ],
            dependencies: [
                .target(name: "AppearanceDomain"),
                .target(name: "BudgetDomain"),
                .target(name: "DebtDomain"),
                .target(name: "GoalDomain"),
                .target(name: "InvestmentDomain"),
                .target(name: "PersistenceKit"),
                .target(name: "PhantomExpenseDomain"),
                .target(name: "TransactionDomain"),
                .target(name: "WealthDomain"),
                .target(name: "WellnessDomain"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "AuthFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).auth-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/AuthFeature/Sources",
                "Packages/Features/AuthFeature/Resources",
            ],
            dependencies: [
                .target(name: "AuthDomain"),
                .target(name: "KasoDesignSystem"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "AuthFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).auth-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/AuthFeature/Tests",
            ],
            dependencies: [
                .target(name: "AuthFeature"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "AppearanceFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).appearance-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/AppearanceFeature/Sources",
                "Packages/Features/AppearanceFeature/Resources",
            ],
            dependencies: [
                .target(name: "AppearanceDomain"),
                .target(name: "KasoDesignSystem"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "AppearanceFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).appearance-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/AppearanceFeature/Tests",
            ],
            dependencies: [
                .target(name: "AppearanceFeature"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "OnboardingFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).onboarding-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/OnboardingFeature/Sources",
                "Packages/Features/OnboardingFeature/Resources",
            ],
            dependencies: [
                .target(name: "KasoDesignSystem"),
                .target(name: "OnboardingDomain"),
                .target(name: "TransactionDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "OnboardingFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).onboarding-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/OnboardingFeature/Tests",
            ],
            dependencies: [
                .target(name: "OnboardingDomain"),
                .target(name: "OnboardingFeature"),
                .target(name: "TransactionDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "KasoRootFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).root-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/KasoRootFeature/Sources",
                "Packages/Features/KasoRootFeature/Resources",
            ],
            dependencies: [
                .target(name: "AppearanceDomain"),
                .target(name: "AppearanceFeature"),
                .target(name: "AuthDomain"),
                .target(name: "AuthFeature"),
                .target(name: "BudgetDomain"),
                .target(name: "DebtFeature"),
                .target(name: "GoalDomain"),
                .target(name: "HoursOfLifeFeature"),
                .target(name: "InvestmentDomain"),
                .target(name: "InvestmentFeature"),
                .target(name: "OnboardingDomain"),
                .target(name: "OnboardingFeature"),
                .target(name: "PhantomExpenseDomain"),
                .target(name: "PhantomExpenseFeature"),
                .target(name: "TransactionDomain"),
                .target(name: "TransactionFeature"),
                .target(name: "WealthDomain"),
                .target(name: "WealthFeature"),
                .target(name: "WellnessDomain"),
                .target(name: "WellnessFeature"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "KasoRootFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).root-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/KasoRootFeature/Tests",
            ],
            dependencies: [
                .target(name: "BudgetDomain"),
                .target(name: "KasoRootFeature"),
                .target(name: "OnboardingDomain"),
                .target(name: "TransactionDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "TransactionFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).transaction-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/TransactionFeature/Sources",
                "Packages/Features/TransactionFeature/Resources",
            ],
            dependencies: [
                .target(name: "BudgetDomain"),
                .target(name: "GoalDomain"),
                .target(name: "InsightDomain"),
                .target(name: "KasoDesignSystem"),
                .target(name: "SubscriptionDomain"),
                .target(name: "TransactionDomain"),
                .target(name: "WellnessDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "TransactionFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).transaction-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/TransactionFeature/Tests",
            ],
            dependencies: [
                .target(name: "GoalDomain"),
                .target(name: "InsightDomain"),
                .target(name: "SubscriptionDomain"),
                .target(name: "TransactionFeature"),
                .target(name: "WellnessDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "DebtFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).debt-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/DebtFeature/Sources",
                "Packages/Features/DebtFeature/Resources",
            ],
            dependencies: [
                .target(name: "DebtDomain"),
                .target(name: "KasoDesignSystem"),
                .target(name: "WealthDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "DebtFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).debt-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/DebtFeature/Tests",
            ],
            dependencies: [
                .target(name: "DebtFeature"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "InvestmentFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).investment-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/InvestmentFeature/Sources",
                "Packages/Features/InvestmentFeature/Resources",
            ],
            dependencies: [
                .target(name: "InvestmentDomain"),
                .target(name: "KasoDesignSystem"),
                .target(name: "WealthDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "InvestmentFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).investment-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/InvestmentFeature/Tests",
            ],
            dependencies: [
                .target(name: "InvestmentDomain"),
                .target(name: "InvestmentFeature"),
                .target(name: "WealthDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "PhantomExpenseFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).phantom-expense-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/PhantomExpenseFeature/Sources",
                "Packages/Features/PhantomExpenseFeature/Resources",
            ],
            dependencies: [
                .target(name: "KasoDesignSystem"),
                .target(name: "PhantomExpenseDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "PhantomExpenseFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).phantom-expense-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/PhantomExpenseFeature/Tests",
            ],
            dependencies: [
                .target(name: "PhantomExpenseDomain"),
                .target(name: "PhantomExpenseFeature"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "WealthFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).wealth-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/WealthFeature/Sources",
                "Packages/Features/WealthFeature/Resources",
            ],
            dependencies: [
                .target(name: "KasoDesignSystem"),
                .target(name: "WealthDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "WealthFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).wealth-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/WealthFeature/Tests",
            ],
            dependencies: [
                .target(name: "WealthFeature"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "HoursOfLifeFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).hours-of-life-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/HoursOfLifeFeature/Sources",
                "Packages/Features/HoursOfLifeFeature/Resources",
            ],
            dependencies: [
                .target(name: "KasoDesignSystem"),
                .target(name: "TransactionDomain"),
                .target(name: "WellnessDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "HoursOfLifeFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).hours-of-life-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/HoursOfLifeFeature/Tests",
            ],
            dependencies: [
                .target(name: "HoursOfLifeFeature"),
                .target(name: "TransactionDomain"),
                .target(name: "WellnessDomain"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "WellnessFeature",
            destinations: destinations,
            product: .staticFramework,
            bundleId: "\(bundlePrefix).wellness-feature",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/WellnessFeature/Sources",
                "Packages/Features/WellnessFeature/Resources",
            ],
            dependencies: [
                .target(name: "HoursOfLifeFeature"),
                .target(name: "KasoDesignSystem"),
                .target(name: "PhantomExpenseFeature"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
        .target(
            name: "WellnessFeatureTests",
            destinations: destinations,
            product: .unitTests,
            bundleId: "\(bundlePrefix).wellness-feature-tests",
            deploymentTargets: deploymentTarget,
            infoPlist: .default,
            buildableFolders: [
                "Packages/Features/WellnessFeature/Tests",
            ],
            dependencies: [
                .target(name: "HoursOfLifeFeature"),
                .target(name: "PhantomExpenseFeature"),
                .target(name: "WellnessFeature"),
                .package(product: "ComposableArchitecture"),
            ],
            settings: projectSettings
        ),
    ]
)
