import GameIDs

extension Resource {
    @inlinable public static func / (self: Self, fiat: Fiat) -> BlocMarket.AssetPair {
        .good(self) / fiat
    }

    @inlinable public static func / (fiat: Fiat, self: Self) -> BlocMarket.AssetPair {
        fiat / .good(self)
    }
}
extension Resource {
    @inlinable public static func / (self: Self, tile: Address) -> LocalMarkets.Key {
        .init(location: tile, resource: self)
    }

    @available(*, unavailable, message: "resource must precede tile")
    @inlinable public static func / (tile: Address, self: Self) -> LocalMarkets.Key {
        .init(location: tile, resource: self)
    }
}
