import Assert
import Fraction
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
@frozen public struct WorldMarkets: ~Copyable {
    @usableFromInline let settings: Settings
    @usableFromInline var table: OrderedDictionary<WorldMarket.ID, WorldMarket>

    @inlinable public init(
        settings: Settings = .default,
        table: OrderedDictionary<WorldMarket.ID, WorldMarket> = [:],
    ) {
        self.settings = settings
        self.table = table
    }
}
extension WorldMarkets {
    public subscript(_ pair: WorldMarket.ID) -> LiquidityPool {
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
                let new: WorldMarket = self.settings.new(pair)
                yield &self.table[pair, default: new].canonical
            } else {
                let new: WorldMarket = self.settings.new(pair.conjugated)
                yield &self.table[pair.conjugated, default: new].conjugate
            }
        }
    }

    @inlinable public func price(of resource: Resource, in currency: CurrencyID) -> Double {
        self.table[resource / currency]?.price ?? 1
    }

    public mutating func turn() {
        for i: Int in self.table.values.indices {
            self.table.values[i].turn(history: self.settings.history)
        }
    }
}
extension WorldMarkets {
    @inlinable public var markets: OrderedDictionary<WorldMarket.ID, WorldMarket> {
        self.table
    }
}
extension WorldMarkets {
    /// This has O(n²) complexity, where n is the number of trading partners.
    public mutating func arbitrate(
        currency: CurrencyID,
        partners: [CurrencyID],
        capital: inout Int64
    ) -> [ArbitrageOpportunity] {
        partners.reduce(into: []) {
            if  let arbitrage: ArbitrageOpportunity = self.arbitrate(
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
    @inlinable public mutating func arbitrate(
        resource: Resource,
        currency: CurrencyID,
        partners: [CurrencyID],
        capital: inout Int64
    ) -> ArbitrageOpportunity? {
        self.arbitrate(
            resource: .good(resource),
            currency: currency,
            partners: partners,
            capital: &capital
        )
    }

    /// Attempts to find and execute profitable triangular arbitrage loops.
    @inlinable public mutating func arbitrate(
        resource: WorldMarket.Asset,
        currency: CurrencyID,
        partners: [CurrencyID],
        capital: inout Int64
    ) -> ArbitrageOpportunity? {
        var best: ArbitrageOpportunity? = nil
        for foreign: CurrencyID in partners {
            guard
            let trade: (profit: Int64, size: Int64) = self.evaluate(
                resource: resource,
                currency: currency,
                foreign: foreign,
                capital: capital
            ) else {
                continue
            }

            if  trade.profit > best?.profit ?? 0 {
                best = .init(market: foreign, profit: trade.profit, volume: trade.size)
            }
        }

        // 6. Execution
        guard let match: ArbitrageOpportunity = best else {
            return nil
        }

        self.execute(
            resource: resource,
            currency: currency,
            triangle: match,
            capital: &capital
        )

        return match
    }

    public mutating func execute(
        resource: WorldMarket.Asset,
        currency: CurrencyID,
        triangle: ArbitrageOpportunity,
        capital: inout Int64
    ) {
        var v: Int64 = self[currency / resource].swap(&capital, limit: triangle.volume)
        var f: Int64 = self[resource / triangle.market].sell(&v)
        let l: Int64 = self[triangle.market / currency].sell(&f)

        // Accounting sanity check
        #assert(v == 0, "Not all of the exported resource was sold in the arbitrage loop!!!")
        #assert(f == 0, "Not all of the foreign currency was sold in the arbitrage loop!!!")

        capital += l
    }

    public func evaluate(
        resource: WorldMarket.Asset,
        currency: CurrencyID,
        foreign: CurrencyID,
        capital: Int64
    ) -> ArbitrageOpportunity? {
        guard let trade: (profit: Int64, size: Int64) = self.evaluate(
            resource: resource,
            currency: currency,
            foreign: foreign,
            capital: capital
        ) else {
            return nil
        }

        return .init(market: foreign, profit: trade.profit, volume: trade.size)
    }

    /// The algorithm uses a Linear Approximation to determine the optimal trade size
    /// in O(1) time per route, rather than iteratively searching for the peak.
    @usableFromInline func evaluate(
        resource: WorldMarket.Asset,
        currency: CurrencyID,
        foreign: CurrencyID,
        capital: Int64
    ) -> (profit: Int64, size: Int64)? {
        if  case .fiat(foreign) = resource {
            return nil
        }

        // 1. Snapshot the Pools (O(1) Access)
        // The subscript logic guarantees these are oriented as Base -> Quote for our direction.
        // Loop: Currency -> Resource -> Foreign -> Currency
        let p: (LiquidityPool, LiquidityPool, LiquidityPool) = (
            self[currency / resource],
            self[resource / foreign],
            self[foreign / currency],
        )

        // 2. "Flash Check" via Spot Price (Double Math)
        // Calculate the infinitesimal spot price of the entire loop (Π).
        let s: (Double, Double, Double) = (
            p.0.price,
            p.1.price,
            p.2.price
        )

        // filter out unprofitable loops early, and loops that make less than 0.1% profit
        let Π: Double = s.0 * s.1 * s.2
        if  Π <= 1.001 {
            return nil
        }

        // 3. Calculate Optimal Trade Size (Linear Approximation)
        // Formula: x* ≈ (Π - 1) / (2 * Sum(1/X_n))
        // This estimates the input amount where Marginal Return = 1.0 (Peak Profit).
        let f: (Double, Double, Double) = (
            1 / Double.init(p.0.assets.base),
            s.0 / Double.init(p.1.assets.base),
            s.1 * s.0 / Double.init(p.2.assets.base)
        )
        let friction: Double = f.0 + f.1 + f.2
        let optimum: Double = (Π - 1.0) / (2.0 * friction)

        // 4. Safety Clamping
        // We multiply by 0.99 to account for the convexity of the CPMM curve (the linear
        // guess usually slightly overshoots). We also strictly clamp to available capital
        // and the shallowest pool depth to prevent pool draining.
        let bottleneck: Int64 = min(p.0.assets.base, min(p.1.assets.base, p.2.assets.base))
        let limit: Int64 = min(capital, bottleneck)

        let quantity: Int64 = min(Int64.init(optimum * 0.99), limit)
        if  quantity <= 0 {
            return nil
        }

        // 5. Verify Exact Profit (Integer Math)
        // We simulate the trade with the guessed size to get the true integer profit.

        let (cost, exportable): (cost: Int64, Int64) = p.0.assets.quote(quantity)
        /// This is how much we would receive (`received`) in foreign currency. Some of the
        /// exported resource might not get sold.
        let (exported, received): (cost: Int64, Int64)  = p.1.assets.quote(exportable)
        /// This is how much we would receive (`revenue`) in the local currency after converting
        /// the proceeds (`received`). Some of the foreign currency might not get sold.
        let (converted, revenue): (cost: Int64, Int64)  = p.2.assets.quote(received)

        /// Compute how much `resource` we would have to sell in this market to get the
        /// amount of foreign currency that we can actually convert back, which may be less
        /// than the total exportable amount, or even the exportable amount in this market.
        let actual: (cost: Int64, volume: Int64)
        if  converted < received {
            // we are bottlenecked on forex conversion, compute the amount of resource we would
            // need to sell to get at most `converted` foreign currency

            // this isn’t really a useful signal about the liquidity of the forex market, we
            // only do it to make sure the exact quantities line up
            actual.volume = p.1.assets.quote(.max, limit: converted).cost
        } else {
            actual.volume = exported
        }

        /// Now let’s compute how much it would actually cost just to buy the amount of
        /// `resource` that we can actually export to this market.
        if  actual.volume < exportable {
            actual.cost = p.0.assets.quote(.max, limit: actual.volume).cost
        } else {
            actual.cost = cost
        }

        #assert(actual.volume <= exported, "Exported more resource than we could sell!!!")
        #assert(actual.cost <= cost, "Spent more capital than we had!!!")

        let profit: Int64 = revenue - actual.cost
        return profit > 0 ? (profit, actual.volume) : nil
    }
}
