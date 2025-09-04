import D
import GameEconomy
import GameRules
import JavaScriptKit
import JavaScriptInterop

extension ResourceInputs {
    var fulfilled: Double {
        min(
            self.inelastic.values.reduce(1) { min($0, $1.fulfilled) },
            self.tradeable.values.reduce(1) { min($0, $1.fulfilled) },
        )
    }

    var valuation: Int64 {
        self.tradeable.values.reduce(0) { $0 + $1.valueAcquired }
    }

    func width(limit: Int64, tier: ResourceTier) -> Int64 {
        zip(self.tradeable.values, tier.tradeable).reduce(limit) {
            let (resource, (_, amount)) : (TradeableInput, (Resource, Int64)) = $1
            return min($0, resource.unitsAcquired / amount)
        }
    }
}
extension ResourceInputs {
    public func tooltipDemand(
        _ id: Resource,
        tier: ResourceTier,
        unit: String,
        factor: Double,
    ) -> Tooltip? {
        guard let amount: Int64 = tier.tradeable[id] ?? tier.inelastic[id] else {
            return nil
        }

        let unitsConsumed: Int64
        let unitsDemanded: Int64

        if  let input: TradeableInput = self.tradeable[id] {
            unitsConsumed = input.unitsConsumed
            unitsDemanded = input.unitsDemanded
        } else if
            let input: InelasticInput = self.inelastic[id] {
            unitsConsumed = input.unitsConsumed
            unitsDemanded = input.unitsDemanded
        } else {
            return nil
        }

        return .instructions {
            $0["Consumed today", +] = unitsConsumed[/3] / unitsDemanded
            $0[>] {
                $0["Demand per \(unit)"] = (factor * Double.init(amount))[..3]
            }
        }
    }

    func tooltipStockpile(_ id: Resource) -> Tooltip? {
        if  let input: TradeableInput = self.tradeable[id] {
            return .instructions {
                let change: Int64 = input.unitsPurchased - input.unitsConsumed

                $0["Total stockpile", +] = input.unitsAcquired[/3] <- input.unitsAcquired - change
                $0[>] {
                    $0["Average cost"] = ??input.averageCost[..2]
                    $0["Supply (days)"] = input.unitsAcquired == 0
                        ? nil
                        : (Double.init(input.unitsAcquired) / Double.init(input.unitsDemanded))[..3]
                }
                $0["Purchased today", +] = +?input.unitsPurchased[/3]
                $0["Returned today", +] = +?input.unitsReturned[/3]
            }
        } else if let input: InelasticInput = self.inelastic[id] {
            return .instructions {
                // We always want this to show, for the indent to make sense
                $0["Purchased today", +] = +input.unitsConsumed[/3]
                $0[>] {
                    $0["Average cost"] = ??input.averageCost[..2]
                }
            }
        } else {
            return nil
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
        if  let input: TradeableInput = self.tradeable[id],
            let price: Candle<Double> = market.tradeable {
            return .instructions {
                $0["Today’s closing price", -] = price.c[..2] <- price.o
                $0[>] = input.price == price.c ? nil : """
                Due to their position in line, and the available liquidity on the market, the \
                average price they actually paid today was \(em: input.price[..2])
                """
                $0[>] = input.price <= price.l ? nil : """
                The luckiest buyers paid \(em: price.l[..2]) today
                """
            }
        } else if
            let _: InelasticInput = self.inelastic[id],
            let (yesderday, today): (LocalMarketState, LocalMarketState) = market.inelastic {
            return .instructions {
                $0["Today’s local price", -] = today.price[/3] <- yesderday.price
                $0[>] {
                    $0["Supply in this tile", +] = today.supply[/3] <- yesderday.supply
                    $0["Demand in this tile", -] = today.demand[/3] <- yesderday.demand
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
                    There are not enough producers in this region, and the price will increase \
                    if the situation persists
                    """
                }

            }
        } else {
            return nil
        }
    }
}
extension ResourceInputs {
    @frozen public enum ObjectKey: JSString, Sendable {
        case tradeable = "t"
        case inelastic = "i"
    }
}
extension ResourceInputs: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.tradeable] = self.tradeable
        js[.inelastic] = self.inelastic
    }
}
extension ResourceInputs: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            tradeable: try js[.tradeable].decode(),
            inelastic: try js[.inelastic].decode()
        )
    }
}
