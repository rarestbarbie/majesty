import GameIDs
import LiquidityPool
import OrderedCollections

/// To spend all of an amount of currency to buy a resource:
///
/// ```swift
/// $0[currency / resource].swap(currencyAmount)
/// ```
///
/// To spend up to a given amount of currency to buy up to a specific amount of a resource:
/// ```swift
/// $0[currency / resource].swap(&currencyAmount, limit: resourceAmount)
/// ```
///
/// To sell all of a resource for currency:
///
/// ```swift
/// $0[resource / currency].swap(resourceAmount)
/// ```
///
/// To sell up to a given amount of a resource until receiving a maximum amount of currency:
/// ```swift
/// $0[resource / currency].swap(&resourceAmount, limit: currencyAmount)
/// ```
@frozen public struct Exchange: ~Copyable {
    @usableFromInline let settings: Settings
    @usableFromInline var table: OrderedDictionary<Market.AssetPair, Market>

    @inlinable public init(
        settings: Settings = .default,
        table: OrderedDictionary<Market.AssetPair, Market> = [:],
    ) {
        self.settings = settings
        self.table = table
    }
}
extension Exchange {
    public subscript(_ pair: Market.AssetPair) -> LiquidityPool {
        get {
            self.table[pair]?.canonical ??
            self.table[pair.conjugated, default: self.settings.new(pair.conjugated)].conjugate
        }
        _modify {
            if  let i: Int = self.table.index(forKey: pair) {
                yield &self.table.values[i].canonical
            } else if
                let i: Int = self.table.index(forKey: pair.conjugated) {
                yield &self.table.values[i].conjugate
            } else if pair.x < pair.y {
                let new: Market = self.settings.new(pair)
                yield &self.table[pair, default: new].canonical
            } else {
                let new: Market = self.settings.new(pair.conjugated)
                yield &self.table[pair.conjugated, default: new].conjugate
            }
        }
    }

    @inlinable public func price(of resource: Resource, in currency: Fiat) -> Double {
        self.table[resource / currency]?.current.c ?? 1
    }

    public mutating func turn() {
        for i: Int in self.table.values.indices {
            self.table.values[i].turn(history: self.settings.history)
        }
    }
}
extension Exchange {
    @inlinable public var markets: OrderedDictionary<Market.AssetPair, Market> {
        self.table
    }
}
extension Exchange {
    /// This has O(n²) complexity, where n is the number of trading partners.
    public mutating func arbitrate(
        currency: Fiat,
        partners: [Fiat],
        capital: inout Int64
    ) -> [ResourceArbitrage] {
        partners.reduce(into: []) {
            if let arbitrage: ResourceArbitrage = self.arbitrate(
                    resource: .fiat($1),
                    currency: currency,
                    partners: partners,
                    capital: &capital
                ) {
                $0.append(arbitrage)
            }
        }
    }

    /// This has O(n) complexity, where n is the number of trading partners.
    ///
    /// -   Parameter `resource`:
    ///     The resource to export from the local market.
    /// -   Parameter `currency`:
    ///     The currency to use for the initial purchase.
    /// -   Parameter `partners`:
    ///     The list of foreign markets to consider for arbitrage.
    /// -   Parameter `capital`:
    ///     The amount of funds available for the initial purchase.
    ///     This has units of `currency`.
    public mutating func arbitrate(
        resource: Resource,
        currency: Fiat,
        partners: [Fiat],
        capital: inout Int64
    ) -> ResourceArbitrage? {
        self.arbitrate(
            resource: .good(resource),
            currency: currency,
            partners: partners,
            capital: &capital
        )
    }

    @_spi(testable) public mutating func arbitrate(
        resource: Market.Asset,
        currency: Fiat,
        partners: [Fiat],
        capital: inout Int64
    ) -> ResourceArbitrage? {
        /// This is the maximum amount of `resource` that we can export from the local market,
        /// and how much of the `capital` it would cost.
        let export: (cost: Int64, amount: Int64) = self[currency / resource].assets.quote(
            capital
        )
        var best: ResourceArbitrage.Opportunity? = nil

        for foreign: Fiat in partners {
            if case .fiat(let fiat) = resource, fiat == foreign {
                // Skip the same currency.
                continue
            }

            /// This is how much we would receive (`f`) in foreign currency. Some of the
            /// exported resource might not get sold.
            let (e, f): (cost: Int64, Int64) = self[resource / foreign].assets.quote(
                export.amount
            )
            /// This is how much we would receive (`l`) in the local currency after converting
            /// the proceeds (`f`). Some of the foreign currency might not get sold.
            let (k, l): (cost: Int64, Int64) = self[foreign / currency].assets.quote(f)

            /// Compute how much `resource` we would have to sell in this market to get the
            /// amount of foreign currency that we can actually convert back, which may be less
            /// than the total exportable amount, or even the exportable amount in this market.
            let bottleneckedOnForex: Bool = k < f
            let volume: Int64 = bottleneckedOnForex
                ? self[resource / foreign].assets.quote(.max, limit: k).cost
                : e

            /// Now let’s compute how much it would actually cost just to buy the amount of
            /// `resource` that we can actually export to this market.
            let actual: (cost: Int64, _) = self[currency / resource].assets.quote(
                .max,
                limit: volume
            )

            assert(volume <= e)
            assert(actual.cost <= export.cost)

            let profit: Int64 = l - actual.cost
            if  profit > best?.profit ?? 0 {
                best = .init(
                    market: foreign,
                    profit: profit,
                    volume: volume,
                    bottleneckedOnForex: bottleneckedOnForex
                )
            }
        }

        guard
        let best: ResourceArbitrage.Opportunity else {
            // No arbitrage opportunity.
            return nil
        }

        var v: Int64 = self[currency / resource].swap(&capital, limit: best.volume)

        assert(v == best.volume)

        var f: Int64 = self[resource / best.market].sell(&v)
        let l: Int64 = self[best.market / currency].sell(&f)

        assert(v == 0)
        assert(f == 0)

        capital += l

        return .init(
            exported: best.volume,
            proceeds: l,
            currency: best.market
        )
    }
}
