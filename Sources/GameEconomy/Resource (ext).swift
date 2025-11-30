import GameIDs

extension Resource {
    @inlinable public static func / (self: Self, fiat: CurrencyID) -> WorldMarket.ID {
        .good(self) / fiat
    }

    @inlinable public static func / (fiat: CurrencyID, self: Self) -> WorldMarket.ID {
        fiat / .good(self)
    }
}
extension Resource {
    @inlinable public static func / (self: Self, tile: Address) -> LocalMarket.ID {
        .init(location: tile, resource: self)
    }

    @available(*, unavailable, message: "resource must precede tile")
    @inlinable public static func / (tile: Address, self: Self) -> LocalMarket.ID {
        .init(location: tile, resource: self)
    }
}
