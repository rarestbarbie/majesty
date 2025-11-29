import GameIDs

extension CurrencyID {
    @inlinable public static func / (a: Self, b: Self) -> WorldMarket.ID {
        .init(.fiat(a), .fiat(b))
    }

    @inlinable static func / (a: Self, b: WorldMarket.Asset) -> WorldMarket.ID {
        .init(.fiat(a), b)
    }

    @inlinable static func / (a: WorldMarket.Asset, b: Self) -> WorldMarket.ID {
        .init(a, .fiat(b))
    }
}
