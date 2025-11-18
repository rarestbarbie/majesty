import D
import GameEconomy
import GameIDs
import GameUI
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
            let (resource, (_, amount)): (ResourceInput, (Resource, Int64)) = $1
            return min($0, resource.units.total / amount)
        }
        return zip(self.tradeable.values, tier.tradeable).reduce(limit) {
            let (resource, (_, amount)): (ResourceInput, (Resource, Int64)) = $1
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
        let amount: Int64
        let input: ResourceInput?

        if  let tradeable: Int64 = tier.tradeable[id] {
            amount = tradeable
            input = self.tradeable[id]
        } else if
            let inelastic: Int64 = tier.inelastic[id] {
            amount = inelastic
            input = self.inelastic[id]
        } else {
            return nil
        }

        guard let input: ResourceInput else {
            return nil
        }

        return .instructions {
            $0["Consumed today", +] = input.unitsConsumed[/3] / input.unitsDemanded
            $0[>] {
                $0["Demand per \(unit)"] = (productivity * factor * Double.init(amount))[..3]
                $0[>] {
                    $0["Base"] = amount[/3]
                    $0[productivityLabel, +] = productivity[%2]
                    $0["Efficiency", -] = +?(1 - factor)[%2]
                }
                $0["Average cost"] = input.averageCost?[..2]
            }
        }
    }

    func tooltipStockpile(_ id: Resource, country: CountryProperties) -> Tooltip? {
        let currency: String = country.currency.name

        let units: Reservoir
        let value: Reservoir
        let unitsReturned: Int64
        let supplyDays: Double?

        if  let input: ResourceInput = self.tradeable[id] {
            units = input.units
            value = input.value
            unitsReturned = input.unitsReturned
            supplyDays = input.units.total == 0 ? nil : (
                Double.init(input.units.total) / Double.init(input.unitsDemanded)
            )
        } else if
            let input: ResourceInput = self.inelastic[id] {
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
            inelastic: LocalMarket.State?,
            tradeable: BlocMarket.State?
        ),
    ) -> Tooltip? {
        if  let filled: ResourceInput = self.tradeable[id],
            let price: Candle<Double> = market.tradeable?.history.last?.prices {
            return .instructions {
                $0["Today’s closing price", -] = price.c[..2] <- price.o

                guard let actual: Double = filled.price else {
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
            let filled: ResourceInput = self.inelastic[id],
            let market: LocalMarket.State = market.inelastic {
            let today: LocalMarket.Interval = market.today
            let yesterday: LocalMarket.Interval = market.yesterday
            return .instructions {
                // Show the bid price here, because the ask price is what they actually paid,
                // and that is shown several lines below
                $0["Today’s local price", -] = today.bid.value[..] <- yesterday.bid.value
                $0[>] {
                    $0["Supply in this tile", +] = today.supply[/3] <- yesterday.supply
                    $0["Demand in this tile", -] = today.demand[/3] <- yesterday.demand
                }
                $0["Local stockpile", +] = market.stockpile[/3]
                $0[>] {
                    $0["Stabilization fund value", +] = market.stabilizationFund[/3]
                }

                if  let average: Double = filled.price {
                    let spread: Double = today.spread
                    $0[>] = """
                    Due to the local bid-ask spread of \(
                        spread[%2], style: spread > 0.005 ? .neg : .em
                    ), the average price they actually paid \
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
                    to decline due to their \(floor.label) of \(em: floor.price.value[..])
                    """
                } else if
                    let cap: LocalPriceLevel = market.limit.max,
                        cap.price <= today.ask {
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
