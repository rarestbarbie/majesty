// swift-tools-version:6.1
import CompilerPluginSupport
import PackageDescription
import typealias Foundation.ProcessInfo

let package: Package = .init(
    name: "majesty",
    products: [
        .executable(name: "engine", targets: ["GameAPI"]),
        .executable(name: "vector", targets: ["VectorTest"]),
        .executable(name: "integration-tests", targets: ["GameIntegrationTests"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "602.0.0"),
        // .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.36.0"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", branch: "main"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.3"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.2.1"),
        // .package(url: "https://github.com/ordo-one/bijection", from: "0.1.7"),
        .package(url: "https://github.com/ordo-one/bijection", branch: "master"),
        .package(url: "https://github.com/ordo-one/package-distributions", from: "0.2.0"),
        .package(url: "https://github.com/tayloraswift/dollup", from: "0.5.0"),
        .package(url: "https://github.com/tayloraswift/d", from: "0.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "GameAPI",
            dependencies: [
                .target(name: "GameEngine"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
        ),

        .executableTarget(
            name: "GameIntegrationTests",
            dependencies: [
                .target(name: "GameEngine"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
            path: "IntegrationTests/Swift",
        ),

        .executableTarget(
            name: "VectorTest",
            dependencies: [
                .target(name: "Vector"),
            ],
        ),


        .executableTarget(
            name: "DollupSettings",
            dependencies: [
                .product(name: "DollupConfig", package: "dollup"),
            ],
            path: "Plugins/DollupSettings",
        ),

        .plugin(
            name: "DollupFormat",
            capability: .command(
                intent: .custom(verb: "format", description: "format source files"),
                permissions: [.writeToPackageDirectory(reason: "code formatter")],
            ),
            dependencies: [
                .target(name: "DollupSettings"),
            ]
        ),


        .macro(
            name: "AssertMacro",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "Assert",
            dependencies: ["AssertMacro"]
        ),

        .target(
            name: "Color",
        ),

        .target(
            name: "ColorText",
            dependencies: [
                .product(name: "D", package: "d"),
            ],
        ),

        .target(
            name: "Fraction",
            dependencies: [
            ],
        ),
        .testTarget(
            name: "FractionTests",
            dependencies: [
                .target(name: "Fraction"),
            ]
        ),

        .target(
            name: "GameClock",
            dependencies: [
            ]
        ),

        .target(
            name: "GameConditions",
            dependencies: [
                .target(name: "ColorText"),
                .product(name: "D", package: "d"),
            ],
        ),
        .testTarget(
            name: "GameConditionTests",
            dependencies: [
                .target(name: "GameConditions"),
            ]
        ),

        .target(
            name: "GameEngine",
            dependencies: [
                .target(name: "Assert"),
                .target(name: "GameClock"),
                .target(name: "GameConditions"),
                .target(name: "GameEconomy"),
                .target(name: "GameMetrics"),
                .target(name: "GameRules"),
                .target(name: "GameStarts"),
                .target(name: "GameState"),
                .target(name: "GameTerrain"),
                .target(name: "GameUI"),
                .target(name: "JavaScriptInterop"),
                .target(name: "Vector"),
                .target(name: "VectorCharts"),
                .target(name: "VectorCharts_JavaScript"),
            ]
        ),

        .target(
            name: "GameEconomy",
            dependencies: [
                .target(name: "Assert"),
                .target(name: "GameIDs"),
                .target(name: "LiquidityPool"),
                .product(name: "D", package: "d"),
                .product(name: "Random", package: "package-distributions"),
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "OrderedCollections", package: "swift-collections"),
                .product(name: "RealModule", package: "swift-numerics"),
            ]
        ),
        .testTarget(
            name: "GameEconomyTests",
            dependencies: [
                .target(name: "GameEconomy"),
            ]
        ),

        .target(
            name: "GameIDs",
            dependencies: [
                .target(name: "Color"),
                .target(name: "GameStateMacros"),
                .target(name: "HexGrids"),
                .product(name: "Bijection", package: "bijection"),
            ]
        ),

        .target(
            name: "GameMetrics",
            dependencies: [
                .target(name: "GameEconomy"),
                .target(name: "JavaScriptInterop"),
                .product(name: "D", package: "d"),
            ]
        ),

        .target(
            name: "GameRules",
            dependencies: [
                .target(name: "Color"),
                .target(name: "GameIDs"),
                .target(name: "GameEconomy"),
                .target(name: "JavaScriptInterop"),
                .product(name: "D", package: "d"),
            ]
        ),

        .target(
            name: "GameStarts",
            dependencies: [
                .target(name: "GameIDs"),
                .target(name: "GameRules"),
            ],
        ),

        .target(
            name: "GameState",
            dependencies: [
                .target(name: "GameIDs"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ],
        ),
        .macro(
            name: "GameStateMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "GameStateTests",
            dependencies: [
                .target(name: "GameState"),
            ]
        ),

        .target(
            name: "GameTerrain",
            dependencies: [
                .target(name: "Color"),
                .target(name: "GameIDs"),
                .target(name: "GameRules"),
                .target(name: "JavaScriptInterop"),
                .target(name: "HexGrids"),
            ]
        ),

        .target(
            name: "GameUI",
            dependencies: [
                .target(name: "ColorText"),
                .target(name: "GameEconomy"),
                .target(name: "GameIDs"),
                .target(name: "JavaScriptInterop"),
                .product(name: "D", package: "d"),
                .product(name: "Bijection", package: "bijection"),
            ]
        ),

        .target(
            name: "HexGrids",
            dependencies: [
                .target(name: "Vector"),
            ],
        ),

        .testTarget(
            name: "HexGridTests",
            dependencies: [
                .target(name: "HexGrids"),
            ],
        ),

        .target(
            name: "JavaScriptInterop",
            dependencies: [
                .product(name: "JavaScriptBigIntSupport", package: "JavaScriptKit"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ]
        ),

        .target(
            name: "LiquidityPool",
            dependencies: [
                .target(name: "Fraction"),
            ]
        ),

        .target(
            name: "Vector",
            linkerSettings: [
                .linkedLibrary("m"),
            ],
        ),

        .testTarget(name: "VectorTests",
            dependencies: [
                .target(name: "Vector"),
            ],
        ),

        .target(
            name: "VectorCharts",
            dependencies: [
                .target(name: "Vector"),
            ]
        ),

        .target(
            name: "VectorCharts_JavaScript",
            dependencies: [
                .target(name: "VectorCharts"),
                .target(name: "JavaScriptInterop"),
            ]
        ),
    ]
)

for target: Target in package.targets {
    if case .plugin = target.type {
        continue
    }

    let swift: [SwiftSetting]
    let c: [CSetting]

    switch ProcessInfo.processInfo.environment["SWIFT_NOASSERT"]
    {
    case "1"?, "true"?:
        swift = [
            .enableUpcomingFeature("ExistentialAny"),
        ]

    case "0"?, "false"?, nil:
        swift = [
            .enableUpcomingFeature("ExistentialAny"),
            .define("TESTABLE"),
        ]

    case let value?:
        fatalError("Unexpected 'SWIFT_NOASSERT' value: \(value)")
    }

    switch ProcessInfo.processInfo.environment["SWIFT_WASM_SIMD128"]
    {
    case "1"?, "true"?:
        c = [
            .unsafeFlags(["-msimd128"])
        ]

    case "0"?, "false"?, nil:
        c = [
        ]

    case let value?:
        fatalError("Unexpected 'SWIFT_WASM_SIMD128' value: \(value)")
    }

    {
        $0 = ($0 ?? []) + swift
    } (&target.swiftSettings)

    if case .macro = target.type {
        // Macros are not compiled with C settings.
        continue
    }

    {
        $0 = ($0 ?? []) + c
    } (&target.cSettings)
}
