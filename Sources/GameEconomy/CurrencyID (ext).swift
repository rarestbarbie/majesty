import GameIDs

extension CurrencyID {
    @inlinable public static func / (a: Self, b: Self) -> BlocMarket.ID {
        .init(.fiat(a), .fiat(b))
    }

    @inlinable static func / (a: Self, b: BlocMarket.Asset) -> BlocMarket.ID {
        .init(.fiat(a), b)
    }

    @inlinable static func / (a: BlocMarket.Asset, b: Self) -> BlocMarket.ID {
        .init(a, .fiat(b))
    }
}
