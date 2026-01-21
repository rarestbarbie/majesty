// swift-tools-version:6.2
import PackageDescription
import typealias Foundation.ProcessInfo

let package: Package = .init(
    name: "majesty-tests",
    products: [
        .executable(name: "engine-tests", targets: ["GameEngineTests"]),
    ],
    dependencies: [
        .package(name: "majesty", path: "..", traits: ["Headless"]),
        .package(url: "https://github.com/tayloraswift/swift-io", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "GameEngineTests",
            dependencies: [
                .product(
                    name: "GameEngine",
                    package: "majesty",

                ),
                .product(name: "SystemIO", package: "swift-io"),
                .product(name: "System_ArgumentParser", package: "swift-io"),
            ],
        ),
    ]
)

for target: Target in package.targets {
    if case .plugin = target.type {
        continue
    }

    let swift: [SwiftSetting]
    let c: [CSetting]

    switch ProcessInfo.processInfo.environment["SWIFT_NOASSERT"] {
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

    switch ProcessInfo.processInfo.environment["SWIFT_WASM_SIMD128"] {
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
