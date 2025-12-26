import D
import Fraction
import GameEconomy
import GameIDs
import GameUI

extension InventorySnapshot {
    struct Produced {
        let origin: MineID?
        let output: ResourceOutput
        let tradeable: Bool
    }
}
extension InventorySnapshot.Produced {
    init(id: ID, value: Value) {
        self.origin = id.mine
        self.output = value.output
        self.tradeable = value.tradeable
    }
}
extension InventorySnapshot.Produced {
    func tooltipSupply(
        tier: ResourceTier,
        details: (inout TooltipInstructionEncoder, Int64) -> () = { _, _ in }
    ) -> Tooltip? {
        let amount: Int64

        if  let tradeable: Int64 = tier.tradeable[self.output.id] {
            amount = tradeable
        } else if
            let segmented: Int64 = tier.segmented[self.output.id] {
            amount = segmented
        } else {
            return nil
        }

        return .instructions {
            $0["Units sold today", +] = self.output.unitsSold[/3] / self.output.units.removed
            $0[>] {
                $0["Proceeds earned", +] = +?self.output.valueSold[/3]
            }
            $0["Stockpiled inventory", +] = self.output.units[/3]
            $0[>] {
                $0["Produced today", +] = self.output.units.added[/3]
            }

            details(&$0, amount)

            if self.output.unitsSold < self.output.units.removed {
                $0[>] = """
                \(neg: (self.output.units.removed - self.output.unitsSold)[/3]) \
                didn’t get sold today
                """
            }
        }
    }

    func tooltipExplainPriceTradeable(market: WorldMarket.State) -> Tooltip? {
        guard let price: Candle<Double> = market.history.last?.prices else {
            return nil
        }

        return .instructions {
            $0["Today’s closing price", +] = price.c[..2] <- price.o

            guard let actual: Double = self.output.price else {
                return
            }

            $0[>] = actual == price.c ? nil : """
            Due to their position in line, and the available liquidity on the market, the \
            average price they actually received today was \(em: actual[..2])
            """
            $0[>] = actual >= price.h ? nil : """
            The luckiest sellers earned \(em: price.h[..2]) today
            """
        }
    }
    func tooltipExplainPriceSegmented(market: LocalMarketSnapshot) -> Tooltip {
        .instructions {
            // Show the ask price here, because the bid price is what they actually
            // received, and that is shown several lines below
            $0["Today’s local price", +] = market.state.Δ.ask.value[..]
            $0[>] {
                $0["Supply in this tile", -] = market.state.Δ.supply[/3]
                $0["Demand in this tile", +] = market.state.Δ.demand[/3]
            }

            $0["Local stockpile", -] = market.state.stockpile[/3]
            $0[>] {
                $0["Stabilization fund value", +] = market.state.stabilizationFund[/3]
            }

            if  let average: Double = self.output.price,
                let _: Int64 = market.shape.storage {
                let spread: Double = market.state.today.spread
                $0[>] = """
                Due to the local bid-ask spread of \(
                    spread[%2], style: .spread(spread)
                ), the average price they actually received \
                today was \(em: average[..2])
                """

                if case .reduced = market.state.today.priceIncrement(
                        stockpile: market.state.stockpile
                    ) {
                    $0[>] = """
                    We are \(em: "dispensing") from the stabilization fund, which is \
                    \(em: "retarding") the price decrease
                    """
                    return
                }
            }

            if market.state.today.supply <= market.state.today.demand {
                $0[>] = """
                There are not enough producers in this region, and the price will increase \
                if the situation persists
                """
            } else if
                let floor: LocalPriceLevel = market.shape.limit.min,
                    floor.price >= market.state.today.bid {
                $0[>] = """
                There are not enough buyers in this region, but the price is not allowed \
                to decline due to their \(floor.label) of \
                \(em: floor.price.value[..])
                """
            } else if
                let cap: LocalPriceLevel = market.shape.limit.max,
                    cap.price <= market.state.today.ask {
                $0[>] = """
                There are not enough producers in this region, but the price is not
                allowed to increase due to their \(cap.label) of \(em: cap.price.value[..])
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
