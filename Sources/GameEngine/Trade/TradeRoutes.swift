import GameEconomy
import GameIDs
import OrderedCollections
import Random

struct TradeRoutes {
    let source: CurrencyID
    var active: OrderedDictionary<TradeRoute.ID, TradeRoute>
    var resources: [Resource]
    var partners: [CurrencyID]
    var capital: Reservoir
}
extension TradeRoutes: Identifiable {
    var id: CurrencyID { self.source }
}
extension TradeRoutes {
    mutating func trade(
        today: GameDate,
        width: Int = 3,
        markets: inout WorldMarkets,
        random: inout PseudoRandom,
    ) {
        let checked: (
            (asset: WorldMarket.Asset, ArbitrageOpportunity?)?,
            (asset: WorldMarket.Asset, ArbitrageOpportunity?)?
        )
        //  search can add up to two new routes per turn, so we should only initiate it if we
        //  are not already over capacity
        if  self.active.count <= width {
            // shop a random resource around to all trading partners
            if  let id: Resource = self.resources.randomElement(using: &random.generator) {
                let asset: WorldMarket.Asset = .good(id)
                checked.0 = (
                    asset,
                    markets.arbitrate(
                        resource: asset,
                        currency: self.source,
                        partners: self.partners,
                        capital: &self.capital.total
                    )
                )
            } else {
                checked.0 = nil
            }
            // also try arbitraging somebody else’s currency (that country will automatically
            // be excluded from consideration, to ensure we have three legged arbitrage)
            if  let id: CurrencyID = self.partners.randomElement(using: &random.generator) {
                let asset: WorldMarket.Asset = .fiat(id)
                checked.1 = (
                    asset,
                    markets.arbitrate(
                        resource: asset,
                        currency: self.source,
                        partners: self.partners,
                        capital: &self.capital.total
                    )
                )
            } else {
                checked.1 = nil
            }
        } else {
            checked = (nil, nil)
        }

        var worst: Int64 = .max
        self.active.update {
            $0.turnToNextDay()

            guard $0.y.profit > 0 else {
                // don’t bother checking routes that were not profitable yesterday
                return true
            }

            // make sure we’re not retrading assets we just checked
            if case $0.id.asset? = checked.0?.asset {
                return true
            }
            if case $0.id.asset? = checked.1?.asset {
                return true
            }
            if  let triangle: ArbitrageOpportunity = markets.evaluate(
                    resource: $0.id.asset,
                    currency: self.source,
                    foreign: $0.id.partner,
                    capital: self.capital.total
                ) {
                markets.execute(
                    resource: $0.id.asset,
                    currency: self.source,
                    triangle: triangle,
                    capital: &self.capital.total)

                $0.z.exported += triangle.volume
                $0.z.profit += triangle.profit

                worst = min(worst, triangle.profit)
            }
            // pruning happens on next step
            return true
        }

        for case let (asset, trade?)? in [checked.0, checked.1] {
            let route: TradeRoute = .init(started: today, partner: trade.market, asset: asset)
            self.active[route.id, default: route].z.report(
                exported: trade.volume,
                profit: trade.profit
            )

            worst = min(worst, trade.profit)
        }

        // if we are at or under capacity, don’t prune any routes (except zero profit ones)
        var excess: Int = self.active.count - width
        if  excess <= 0 {
            worst = 0
        }

        self.active.update {
            // this prevents the rare situation where we have multiple profitable routes but
            // they all have the exact same profit
            if  excess > 0, $0.z.profit <= worst {
                excess -= 1
                return false
            } else if $0.z.profit <= 0 {
                excess -= 1
                return false
            } else {
                return true
            }
        }
    }
}
