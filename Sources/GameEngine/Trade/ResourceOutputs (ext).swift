import D
import Fraction
import GameEconomy
import GameIDs
import GameUI
import JavaScriptKit
import JavaScriptInterop

extension ResourceOutputs {
    public func tooltipSupply(
        _ id: Resource,
        tier: ResourceTier,
        unit: String,
        factor: Double,
        factorLabel: String? = nil,
        productivity: Int64
    ) -> Tooltip? {
        guard let amount: Int64 = tier.tradeable[id] ?? tier.inelastic[id] else {
            return nil
        }

        let units: Reservoir
        let unitsSold: Int64
        let valueSold: Int64

        if  let output: ResourceOutput<Double> = self.tradeable[id] {
            units = output.units
            unitsSold = output.unitsSold
            valueSold = output.valueSold
        } else if
            let output: ResourceOutput<Never> = self.inelastic[id] {
            units = output.units
            unitsSold = output.unitsSold
            valueSold = output.valueSold
        } else {
            return nil
        }

        let productivity: Double = .init(productivity)

        return .instructions {
            $0["Units sold today", +] = unitsSold[/3] / units.removed
            $0[>] {
                $0["Proceeds earned", +] = +?valueSold[/3]
            }
            $0["Stockpiled inventory", +] = units.total[/3] <- units.before
            $0[>] {
                $0["Produced today", +] = units.added[/3]
            }
            $0["Production per \(unit)"] = (productivity * factor * Double.init(amount))[..3]
            $0[>] {
                $0["Base"] = amount[/3]
                $0["Productivity", +] = productivity[%2]
                $0[factorLabel ?? "Efficiency", +] = +?(factor - 1)[%2]
            }
            if unitsSold < units.removed {
                $0[>] = """
                \(neg: (units.removed - unitsSold)[/3]) didn’t get sold today
                """
            }
        }
    }

    func tooltipExplainPrice(
        _ id: Resource,
        _ market: (
            inelastic: LocalMarket?,
            tradeable: Candle<Double>?
        ),
    ) -> Tooltip? {
        if  let output: ResourceOutput<Double> = self.tradeable[id],
            let price: Candle<Double> = market.tradeable {
            return .instructions {
                $0["Today’s closing price", +] = price.c[..2] <- price.o

                guard let actual: Double = output.price else {
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
            let _: ResourceOutput<Never> = self.inelastic[id],
            let market: LocalMarket = market.inelastic {
            let today: LocalMarketState = market.today
            let yesterday: LocalMarketState = market.yesterday
            return .instructions {
                $0["Today’s local price", +] = today.price.value[..] <- yesterday.price.value
                $0[>] {
                    $0["Supply in this tile", -] = today.supply[/3] <- yesterday.supply
                    $0["Demand in this tile", +] = today.demand[/3] <- yesterday.demand
                }

                if today.supply <= today.demand {
                    $0[>] = """
                    There are not enough producers in this region, and the price will increase \
                    if the situation persists
                    """
                } else if
                    let priceFloor: LocalMarket.PriceFloor = market.priceFloor,
                        priceFloor.minimum >= today.price {
                    $0[>] = """
                    There are not enough buyers in this region, but the price is not allowed \
                    to decline due to their \(priceFloor.type) of \
                    \(em: priceFloor.minimum.value[..])
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
