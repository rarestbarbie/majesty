import D
import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

extension ResourceInputs {
    var fulfilled: Double {
        min(
            self.inelastic.values.reduce(1) { min($0, $1.fulfilled) },
            self.tradeable.values.reduce(1) { min($0, $1.fulfilled) },
        )
    }

    var valueAcquired: Int64 {
        self.tradeable.values.reduce(0) { $0 + $1.value.total } +
        self.inelastic.values.reduce(0) { $0 + $1.value.total }
    }

    func width(limit: Int64, tier: ResourceTier) -> Int64 {
        let limit: Int64 = zip(self.inelastic.values, tier.inelastic).reduce(limit) {
            let (resource, (_, amount)): (ResourceInput<Never>, (Resource, Int64)) = $1
            return min($0, resource.units.total / amount)
        }
        return zip(self.tradeable.values, tier.tradeable).reduce(limit) {
            let (resource, (_, amount)): (ResourceInput<Double>, (Resource, Int64)) = $1
            return min($0, resource.units.total / amount)
        }
    }
}
extension ResourceInputs {
    public func tooltipDemand(
        _ id: Resource,
        tier: ResourceTier,
        unit: String,
        factor: Double,
        productivity: Double,
        productivityLabel: String = "Productivity"
    ) -> Tooltip? {
        guard let amount: Int64 = tier.tradeable[id] ?? tier.inelastic[id] else {
            return nil
        }

        let unitsConsumed: Int64
        let unitsDemanded: Int64
        let averageCost: Double?

        if  let input: ResourceInput<Double> = self.tradeable[id] {
            unitsConsumed = input.unitsConsumed
            unitsDemanded = input.unitsDemanded
            averageCost = input.averageCost
        } else if
            let input: ResourceInput<Never> = self.inelastic[id] {
            unitsConsumed = input.unitsConsumed
            unitsDemanded = input.unitsDemanded
            averageCost = input.averageCost
        } else {
            return nil
        }

        return .instructions {
            $0["Consumed today", +] = unitsConsumed[/3] / unitsDemanded
            $0[>] {
                $0["Demand per \(unit)"] = (productivity * factor * Double.init(amount))[..3]
                $0[>] {
                    $0["Base"] = amount[/3]
                    $0[productivityLabel, +] = productivity[%2]
                    $0["Efficiency", -] = +?(1 - factor)[%2]
                }
                $0["Average cost"] = averageCost?[..2]
            }
        }
    }

    func tooltipStockpile(_ id: Resource, country: CountryProperties) -> Tooltip? {
        let currency: String = country.currency.name

        let units: Reservoir
        let value: Reservoir
        let unitsReturned: Int64
        let supplyDays: Double?

        if  let input: ResourceInput<Double> = self.tradeable[id] {
            units = input.units
            value = input.value
            unitsReturned = input.unitsReturned
            supplyDays = input.units.total == 0 ? nil : (
                Double.init(input.units.total) / Double.init(input.unitsDemanded)
            )
        } else if
            let input: ResourceInput<Never> = self.inelastic[id] {
            units = input.units
            value = input.value
            unitsReturned = input.unitsReturned
            supplyDays = nil
        } else {
            return nil
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
        }
    }

    func tooltipExplainPrice(
        _ id: Resource,
        _ market: (
            inelastic: LocalMarket?,
            tradeable: Candle<Double>?
        ),
    ) -> Tooltip? {
        if  let input: ResourceInput<Double> = self.tradeable[id],
            let price: Candle<Double> = market.tradeable {
            return .instructions {
                $0["Today’s closing price", -] = price.c[..2] <- price.o

                guard let actual: Double = input.price else {
                    return
                }

                $0[>] = actual == price.c ? nil : """
                Due to their position in line, and the available liquidity on the market, the \
                average price they actually paid today was \(em: actual[..2])
                """
                $0[>] = actual <= price.l ? nil : """
                The luckiest buyers paid \(em: price.l[..2]) today
                """
            }
        } else if
            let _: ResourceInput<Never> = self.inelastic[id],
            let market: LocalMarket = market.inelastic {
            let today: LocalMarketState = market.today
            let yesterday: LocalMarketState = market.yesterday
            return .instructions {
                $0["Today’s local price", -] = today.price.value[..] <- yesterday.price.value
                $0[>] {
                    $0["Supply in this tile", +] = today.supply[/3] <- yesterday.supply
                    $0["Demand in this tile", -] = today.demand[/3] <- yesterday.demand
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
