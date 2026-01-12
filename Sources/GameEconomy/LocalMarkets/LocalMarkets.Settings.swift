import OrderedCollections

extension LocalMarkets {
    // TODO: local market policies should be centralized here
    @frozen public struct Settings {
        @inlinable public init(
        ) {
        }
    }
}
extension LocalMarkets.Settings {
    @inlinable func new(_ id: LocalMarket.ID) -> LocalMarket {
        let initial: LocalMarket.Interval = .init(
            bid: .init(),
            ask: .init(),
            supply: 0,
            demand: 0
        )
        let state: LocalMarket.State = .init(
            id: id,
            stabilizationFundFees: 0,
            stabilizationFund: .zero,
            stockpile: .zero,
            yesterday: initial,
            today: initial
        )
        return self.load(state)
    }

    @inlinable func load(_ state: LocalMarket.State) -> LocalMarket {
        .init(state: state)
    }

    public func load(
        _ markets: [LocalMarket.State]
    ) -> OrderedDictionary<LocalMarket.ID, LocalMarket> {
        markets.reduce(
            into: .init(minimumCapacity: markets.count)) {
            $0[$1.id] = self.load($1)
        }
    }
}
