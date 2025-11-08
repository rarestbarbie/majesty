import GameIDs

extension Fiat {
    @inlinable public static func / (a: Self, b: Self) -> BlocMarket.AssetPair {
        .init(.fiat(a), .fiat(b))
    }

    @inlinable static func / (a: Self, b: BlocMarket.Asset) -> BlocMarket.AssetPair {
        .init(.fiat(a), b)
    }

    @inlinable static func / (a: BlocMarket.Asset, b: Self) -> BlocMarket.AssetPair {
        .init(a, .fiat(b))
    }
}
extension Fiat {
    @inlinable public static func / (a: Self, b: Resource) -> BlocMarket.AssetPair {
        a / .good(b)
    }

    @inlinable public static func / (a: Resource, b: Self) -> BlocMarket.AssetPair {
        .good(a) / b
    }
}
