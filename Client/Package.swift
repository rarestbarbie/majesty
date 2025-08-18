// swift-tools-version:6.1
import CompilerPluginSupport
import PackageDescription
import typealias Foundation.ProcessInfo

let package: Package = .init(
    name: "test",
    products: [
        .executable(name: "engine", targets: ["GameAPI"]),
        .executable(name: "vector", targets: ["VectorTest"]),
        .executable(name: "integration-tests", targets: ["GameIntegrationTests"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.31.2"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.3"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "GameAPI",
            dependencies: [
                .target(name: "GameState"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
        ),

        .executableTarget(
            name: "GameIntegrationTests",
            dependencies: [
                .target(name: "GameState"),
                .product(name: "JavaScriptEventLoop", package: "JavaScriptKit"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("Testing"),
            ]
        ),

        .executableTarget(
            name: "VectorTest",
            dependencies: [
                .target(name: "Vector"),
            ],
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
                .target(name: "D"),
            ],
        ),

        .target(
            name: "D",
            dependencies: [
                .product(name: "RealModule", package: "swift-numerics"),
            ],
        ),
        .testTarget(
            name: "DTests",
            dependencies: [
                .target(name: "D"),
            ]
        ),

        .target(
            name: "GameConditions",
            dependencies: [
                .target(name: "ColorText"),
                .target(name: "D"),
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
            ],
        ),
        .testTarget(
            name: "GameEngineTests",
            dependencies: [
                .target(name: "GameEngine"),
            ]
        ),

        .target(
            name: "GameEconomy",
            dependencies: [
                .target(name: "Assert"),
                .product(name: "DequeModule", package: "swift-collections"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: "GameEconomyTests",
            dependencies: [
                .target(name: "GameEconomy"),
                .target(name: "GameEngine"),
            ]
        ),

        .target(
            name: "GameRules",
            dependencies: [
                .target(name: "Color"),
                .target(name: "GameEngine"),
                .target(name: "GameEconomy"),
                .target(name: "JavaScriptInterop"),
            ]
        ),

        .target(
            name: "GameState",
            dependencies: [
                .target(name: "Assert"),
                .target(name: "GameConditions"),
                .target(name: "GameEngine"),
                .target(name: "GameEconomy"),
                .target(name: "GameRules"),
                .target(name: "HexGrids"),
                .target(name: "JavaScriptInterop"),
                .target(name: "Random"),
                .target(name: "Vector"),
                .target(name: "VectorCharts"),
                .target(name: "VectorCharts_JavaScript"),
            ]
        ),

        .target(name: "HexGrids",
            dependencies: [
                .target(name: "Vector"),
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
            name: "Random",
            dependencies: [
                .product(name: "RealModule", package: "swift-numerics"),
            ],
            linkerSettings: [
                .linkedLibrary("m"),
            ],
        ),

        .testTarget(
            name: "RandomTests",
            dependencies: [
                .target(name: "Random"),
            ],
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
    let swift: [SwiftSetting]
    let c: [CSetting]

    switch ProcessInfo.processInfo.environment["SWIFT_TESTABLE"]
    {
    case "1"?, "true"?:
        swift = [
            .enableUpcomingFeature("ExistentialAny"),
            .define("TESTABLE")
        ]

    case "0"?, "false"?, nil:
        swift = [
            .enableUpcomingFeature("ExistentialAny"),
        ]

    case let value?:
        fatalError("Unexpected 'SWIFT_TESTABLE' value: \(value)")
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
