import D
import Fraction
import GameEconomy
import GameIDs
import GameUI
import JavaScriptKit
import JavaScriptInterop

extension ResourceOutputs {
    func tooltipSupply(
        _ id: Resource,
        tier: ResourceTier,
        details: (inout TooltipInstructionEncoder, Int64) -> () = { _, _ in }
    ) -> Tooltip? {
        let amount: Int64
        let output: ResourceOutput?

        if  let tradeable: Int64 = tier.tradeable[id] {
            amount = tradeable
            output = self.tradeable[id]
        } else if
            let inelastic: Int64 = tier.inelastic[id] {
            amount = inelastic
            output = self.inelastic[id]
        } else {
            return nil
        }

        guard let output: ResourceOutput = output else {
            return nil
        }

        return .instructions {
            $0["Units sold today", +] = output.unitsSold[/3] / output.units.removed
            $0[>] {
                $0["Proceeds earned", +] = +?output.valueSold[/3]
            }
            $0["Stockpiled inventory", +] = output.units.total[/3] <- output.units.before
            $0[>] {
                $0["Produced today", +] = output.units.added[/3]
            }

            details(&$0, amount)

            if output.unitsSold < output.units.removed {
                $0[>] = """
                \(neg: (output.units.removed - output.unitsSold)[/3]) didn’t get sold today
                """
            }
        }
    }

    func tooltipExplainPrice(
        _ id: Resource,
        _ market: (
            inelastic: LocalMarket.State?,
            tradeable: BlocMarket.State?
        ),
    ) -> Tooltip? {
        if  let filled: ResourceOutput = self.tradeable[id],
            let price: Candle<Double> = market.tradeable?.history.last?.prices {
            return .instructions {
                $0["Today’s closing price", +] = price.c[..2] <- price.o

                guard let actual: Double = filled.price else {
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
        } else if
            let filled: ResourceOutput = self.inelastic[id],
            let market: LocalMarket.State = market.inelastic {
            let today: LocalMarket.Interval = market.today
            let yesterday: LocalMarket.Interval = market.yesterday
            return .instructions {
                // Show the ask price here, because the bid price is what they actually
                // received, and that is shown several lines below
                $0["Today’s local price", +] = today.ask.value[..] <- yesterday.ask.value
                $0[>] {
                    $0["Supply in this tile", -] = today.supply[/3] <- yesterday.supply
                    $0["Demand in this tile", +] = today.demand[/3] <- yesterday.demand
                }

                $0["Local stockpile", -] = market.stockpile[/3]
                $0[>] {
                    $0["Stabilization fund value", +] = market.stabilizationFund[/3]
                }

                if  let average: Double = filled.price, market.storage {
                    let spread: Double = today.spread
                    $0[>] = """
                    Due to the local bid-ask spread of \(
                        spread[%2], style: .spread(spread)
                    ), the average price they actually received \
                    today was \(em: average[..2])
                    """
                }

                if today.supply <= today.demand {
                    $0[>] = """
                    There are not enough producers in this region, and the price will increase \
                    if the situation persists
                    """
                } else if
                    let floor: LocalPriceLevel = market.limit.min,
                        floor.price >= today.bid {
                    $0[>] = """
                    There are not enough buyers in this region, but the price is not allowed \
                    to decline due to their \(floor.label) of \
                    \(em: floor.price.value[..])
                    """
                } else if
                    let cap: LocalPriceLevel = market.limit.max,
                        cap.price <= today.ask {
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
        } else {
            return nil
        }
    }
}
extension ResourceOutputs {
    @frozen public enum ObjectKey: JSString, Sendable {
        case tradeable = "t"
        case inelastic = "i"
    }
}
extension ResourceOutputs: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.tradeable] = self.tradeable
        js[.inelastic] = self.inelastic
    }
}
extension ResourceOutputs: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            tradeable: try js[.tradeable].decode(),
            inelastic: try js[.inelastic].decode()
        )
    }
}
