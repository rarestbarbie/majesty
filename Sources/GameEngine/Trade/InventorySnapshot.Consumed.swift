import D
import GameEconomy
import GameIDs
import GameUI

extension InventorySnapshot {
    struct Consumed {
        let input: ResourceInput
        let tradeable: Bool
        let tradeableDaysReserve: Int64
    }
}
extension InventorySnapshot.Consumed {
    init(id _: ID, value: Value) {
        // resource component of id is already encoded in `value.input.id`
        self.input = value.input
        self.tradeable = value.tradeable
        self.tradeableDaysReserve = value.tradeableDaysReserve
    }
}
extension InventorySnapshot.Consumed {
    func tooltipDemand(
        tier: ResourceTier,
        details: (inout TooltipInstructionEncoder, Int64) -> () = { _, _ in }
    ) -> Tooltip? {
        guard let amount: Int64 = tier.x[self.input.id] else {
            return nil
        }

        return .instructions {
            $0["Consumed today", +] = self.input.unitsConsumed[/3] / self.input.unitsDemanded
            $0[>] {
                details(&$0, amount)
                $0["Average cost"] = self.input.averageCost?[..2]
            }
        }
    }

    func tooltipStockpile(region: RegionalProperties) -> Tooltip? {
        let currency: String = region.currency.name

        let units: Reservoir = self.input.units
        let value: Reservoir = self.input.value
        let unitsReturned: Int64 = self.input.unitsReturned
        let supplyDays: Double?

        if  self.tradeable, self.input.units.total != 0, self.input.unitsDemanded >= 0 {
            supplyDays = Double.init(input.units.total) / Double.init(input.unitsDemanded)
        } else {
            supplyDays = nil
        }

        return .instructions {
            $0["Total stockpile", +] = units.total[/3] <- units.before
            $0[>] {
                $0["Supply (days)"] = supplyDays?[..3]
            }
            if  units.added > 0 {
                $0["Purchased today", +] = units.added[/3]
                $0[>] {
                    $0["Cost (\(currency))"] = value.added[/3]
                }
            } else if unitsReturned > 0 {
                $0["Returned today", +] = +?unitsReturned[/3]
            }

            if  self.tradeable, self.tradeableDaysReserve > 0 {
                $0[>] = """
                Their next purchase is expected in \(em: self.tradeableDaysReserve) \
                \(self.tradeableDaysReserve == 1 ? "day" : "days")
                """
            }
        }
    }

    func tooltipExplainPriceTradeable(market: WorldMarket.State) -> Tooltip? {
        guard
        let price: Candle<Double> = market.history.last?.prices else {
            return nil
        }

        return .instructions {
            $0["Today’s closing price", -] = price.c[..2] <- price.o

            guard let actual: Double = self.input.price else {
                return
            }

            $0[>] = actual == price.c ? nil : """
            Due to their position in line, and the available liquidity on the market, the \
            average price they actually paid was \(em: actual[..2])
            """
            $0[>] = actual <= price.l ? nil : """
            The luckiest buyers paid \(em: price.l[..2]) today
            """
        }
    }
    func tooltipExplainPriceSegmented(market: LocalMarketSnapshot) -> Tooltip {
        .instructions {
            // Show the bid price here, because the ask price is what they actually paid,
            // and that is shown several lines below
            $0["Today’s local price", -] = market.Δ.bid.value[..]
            $0[>] {
                $0["Supply in this tile", +] = market.Δ.supply[/3]
                $0["Demand in this tile", -] = market.Δ.demand[/3]
            }
            $0["Local stockpile", +] = market.stockpile[/3]
            $0[>] {
                $0["Stabilization fund value", +] = market.stabilizationFund[/3]
            }

            if  let average: Double = self.input.price,
                let _: Int64 = market.policy.storage {
                let spread: Double = market.z.spread
                $0[>] = """
                Due to the local bid-ask spread of \(
                    spread[%2], style: .spread(spread)
                ), the average price they actually paid \
                today was \(em: average[..2])
                """

                if case .reduced = market.z.priceIncrement(
                        stockpile: market.stockpile
                    ) {
                    $0[>] = """
                    We are \(em: "dispensing") from the stabilization fund, which is \
                    \(em: "retarding") the price decrease
                    """
                    return
                }
            }
            if market.z.supply <= market.z.demand {
                $0[>] = """
                There are not enough producers in this region, and the price will increase \
                if the situation persists
                """
            } else if
                let floor: LocalPriceLevel = market.policy.limit.min,
                    floor.price >= market.z.bid {
                $0[>] = """
                There are not enough buyers in this region, but the price is not allowed \
                to decline due to their \(floor.label) of \(em: floor.price.value[..])
                """
            } else if
                let cap: LocalPriceLevel = market.policy.limit.max,
                    cap.price <= market.z.ask {
                $0[>] = """
                There is not enough supply in this region, but the price is not allowed \
                to increase due to their \(cap.label) of \(em: cap.price.value[..])
                """
            } else {
                $0[>] = """
                There are not enough buyers in this region, and the price will decline if \
                the situation persists
                """
            }
        }
    }
}
