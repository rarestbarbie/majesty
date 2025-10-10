import GameIDs

extension Fiat {
    @inlinable public static func / (a: Self, b: Self) -> Market.AssetPair {
        .init(.fiat(a), .fiat(b))
    }

    @inlinable static func / (a: Self, b: Market.Asset) -> Market.AssetPair {
        .init(.fiat(a), b)
    }

    @inlinable static func / (a: Market.Asset, b: Self) -> Market.AssetPair {
        .init(a, .fiat(b))
    }
}
extension Fiat {
    @inlinable public static func / (a: Self, b: Resource) -> Market.AssetPair {
        a / .good(b)
    }

    @inlinable public static func / (a: Resource, b: Self) -> Market.AssetPair {
        .good(a) / b
    }
}
