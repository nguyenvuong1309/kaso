// swift-tools-version: 6.0

import PackageDescription

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
        .library(name: "TransactionDomain", targets: ["TransactionDomain"]),
        .library(name: "BudgetDomain", targets: ["BudgetDomain"]),
        .library(name: "OnboardingDomain", targets: ["OnboardingDomain"]),
        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
        .library(name: "AppearanceFeature", targets: ["AppearanceFeature"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
        .library(name: "KasoRootFeature", targets: ["KasoRootFeature"]),
        .library(name: "TransactionFeature", targets: ["TransactionFeature"]),
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
                "KasoRootFeature",
                "PersistenceKit",
            ],
            path: "App/Sources",
            resources: [
                .process("../Resources"),
            ]
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
                "KasoFoundation",
                "OnboardingDomain",
                "TransactionDomain",
            ],
            path: "Packages/Data/PersistenceKit/Sources"
        ),
        .testTarget(
            name: "PersistenceKitTests",
            dependencies: [
                "AppearanceDomain",
                "BudgetDomain",
                "PersistenceKit",
                "TransactionDomain",
            ],
            path: "Packages/Data/PersistenceKit/Tests"
        ),
        .target(
            name: "AuthFeature",
            dependencies: [
                "AuthDomain",
                "KasoDesignSystem",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ],
            path: "Packages/Features/AuthFeature/Sources",
            resources: [
                .process("../Resources"),
            ]
        ),
        .testTarget(
            name: "AuthFeatureTests",
            dependencies: [
                "AuthFeature",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ],
            path: "Packages/Features/AuthFeature/Tests"
        ),
        .target(
            name: "AppearanceFeature",
            dependencies: [
                "AppearanceDomain",
                "KasoDesignSystem",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ],
            path: "Packages/Features/AppearanceFeature/Sources",
            resources: [
                .process("../Resources"),
            ]
        ),
        .testTarget(
            name: "AppearanceFeatureTests",
            dependencies: [
                "AppearanceFeature",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ],
            path: "Packages/Features/AppearanceFeature/Tests"
        ),
        .target(
            name: "OnboardingFeature",
            dependencies: [
                "KasoDesignSystem",
                "OnboardingDomain",
                "TransactionDomain",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ],
            path: "Packages/Features/OnboardingFeature/Sources",
            resources: [
                .process("../Resources"),
            ]
        ),
        .testTarget(
            name: "OnboardingFeatureTests",
            dependencies: [
                "OnboardingDomain",
                "OnboardingFeature",
                "TransactionDomain",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
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
                "OnboardingDomain",
                "OnboardingFeature",
                "TransactionDomain",
                "TransactionFeature",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ],
            path: "Packages/Features/KasoRootFeature/Sources"
        ),
        .testTarget(
            name: "KasoRootFeatureTests",
            dependencies: [
                "BudgetDomain",
                "KasoRootFeature",
                "OnboardingDomain",
                "TransactionDomain",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ],
            path: "Packages/Features/KasoRootFeature/Tests"
        ),
        .target(
            name: "TransactionFeature",
            dependencies: [
                "BudgetDomain",
                "KasoDesignSystem",
                "TransactionDomain",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ],
            path: "Packages/Features/TransactionFeature/Sources",
            resources: [
                .process("../Resources"),
            ]
        ),
        .testTarget(
            name: "TransactionFeatureTests",
            dependencies: [
                "TransactionFeature",
                .product(
                    name: "ComposableArchitecture",
                    package: "swift-composable-architecture"
                ),
            ],
            path: "Packages/Features/TransactionFeature/Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
