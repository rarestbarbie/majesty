import GameIDs

@usableFromInline protocol AggregateDemandColumn {
    var value: Double { get }

    static var zero: Self { get }
    static func aggregate(
        demands: ArraySlice<ResourceInput>,
        markets: borrowing WorldMarkets,
        currency: CurrencyID
    ) -> Self
}
