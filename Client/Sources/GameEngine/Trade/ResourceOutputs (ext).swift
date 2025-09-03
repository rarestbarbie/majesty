import D
import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension ResourceOutputs {
    public func tooltipSupply(
        _ id: Resource,
        tier: ResourceTier,
        unit: String,
        factor: Double,
    ) -> Tooltip? {
        guard let amount: Int64 = tier.tradeable[id] ?? tier.inelastic[id] else {
            return nil
        }

        let unitsProduced: Int64
        let unitsSold: Int64
        let valueSold: Int64

        if  let output: TradeableOutput = self.tradeable[id] {
            unitsProduced = output.unitsProduced
            unitsSold = output.unitsSold
            valueSold = output.valueSold
        } else if
            let output: InelasticOutput = self.inelastic[id] {
            unitsProduced = output.unitsProduced
            unitsSold = output.unitsSold
            valueSold = output.valueSold
        } else {
            return nil
        }

        return .instructions {
            $0["Units sold today", +] = unitsSold[/3] / unitsProduced
            $0[>] {
                $0["Proceeds earned", +] = +?valueSold[/3]
            }
            $0["Production per \(unit)"] = (factor * Double.init(amount))[..3]
            $0[>] {
                $0["Base"] = amount[/3]
                $0["Efficiency", +] = +?(factor - 1)[%2]
            }
            if unitsSold < unitsProduced {
                $0[>] = """
                \(neg: (unitsProduced - unitsSold)[/3]) didn’t get sold today
                """
            }
        }
    }

    func tooltipExplainPrice(
        _ id: Resource,
        _ market: (
            inelastic: (yesterday: LocalMarketState, today: LocalMarketState)?,
            tradeable: Candle<Double>?
        ),
        _ country: Country
    ) -> Tooltip? {
        if  let output: TradeableOutput = self.tradeable[id],
            let price: Candle<Double> = market.tradeable {
            return .instructions {
                $0["Today’s closing price", +] = price.c[..2] <- price.o
                $0[>] = output.price == price.c ? nil : """
                Due to their position in line, and the available liquidity on the market, the \
                average price they actually received today was \(em: output.price[..2])
                """
                $0[>] = output.price >= price.h ? nil : """
                The luckiest sellers earned \(em: price.h[..2]) today
                """
            }
        } else if
            let _: InelasticOutput = self.inelastic[id],
            let (yesterday, today): (LocalMarketState, LocalMarketState) = market.inelastic {
            return .instructions {
                $0["Today’s local price", +] = today.price[/3] <- yesterday.price
                $0[>] {
                    $0["Supply in this tile", -] = today.supply[/3] <- yesterday.supply
                    $0["Demand in this tile", +] = today.demand[/3] <- yesterday.demand
                }

                if today.supply > today.demand {
                    $0[>] = today.price > country.minwage ? """
                    There are not enough buyers in this region, and the price will decline if \
                    the situation persists
                    """ : """
                    There are not enough buyers in this region, but the price is not allowed \
                    to decline due to their Minimum Wage of \(em: country.minwage[/3])
                    """
                } else {
                    $0[>] = """
                    There are not enough producers in this region, and the price will increase
                    if the situation persists
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
