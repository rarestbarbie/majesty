import D
import GameEconomy
import GameIDs
import GameUI
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections

extension ResourceInputs {
    var fulfilled: Double {
        min(
            self.segmented.values.reduce(1) { min($0, $1.fulfilled) },
            self.tradeable.values.reduce(1) { min($0, $1.fulfilled) },
        )
    }

    var valueConsumed: Int64 {
        self.segmented.values.reduce(0) { $0 + $1.valueConsumed } +
        self.tradeable.values.reduce(0) { $0 + $1.valueConsumed }
    }

    var valueAcquired: Int64 {
        self.segmented.values.reduce(0) { $0 + $1.value.total } +
        self.tradeable.values.reduce(0) { $0 + $1.value.total }
    }

    var full: Bool {
        for input: ResourceInput in self.segmented.values where input.units.total < input.unitsDemanded {
            return false
        }
        for input: ResourceInput in self.tradeable.values where input.units.total < input.unitsDemanded {
            return false
        }
        return true
    }

    func width(limit: Int64, tier: ResourceTier, efficiency: Double) -> Int64 {
        min(
            zip(self.segmented.values, tier.segmented).reduce(limit) {
                let (resource, (_, amount)): (ResourceInput, (Resource, Int64)) = $1
                return min($0, resource.width(base: amount, efficiency: efficiency))
            },
            zip(self.tradeable.values, tier.tradeable).reduce(limit) {
                let (resource, (_, amount)): (ResourceInput, (Resource, Int64)) = $1
                return min($0, resource.width(base: amount, efficiency: efficiency))
            }
        )
    }
}
extension ResourceInputs {
    public func tooltipDemand(
        _ id: Resource,
        tier: ResourceTier,
        details: (inout TooltipInstructionEncoder, Int64) -> () = { _, _ in }
    ) -> Tooltip? {
        let amount: Int64
        let input: ResourceInput?

        if  let tradeable: Int64 = tier.tradeable[id] {
            amount = tradeable
            input = self.tradeable[id]
        } else if
            let segmented: Int64 = tier.segmented[id] {
            amount = segmented
            input = self.segmented[id]
        } else {
            return nil
        }

        guard let input: ResourceInput else {
            return nil
        }

        return .instructions {
            $0["Consumed today", +] = input.unitsConsumed[/3] / input.unitsDemanded
            $0[>] {
                details(&$0, amount)
                $0["Average cost"] = input.averageCost?[..2]
            }
        }
    }

    func tooltipStockpile(_ id: Resource, region: RegionalProperties) -> Tooltip? {
        let currency: String = region.currency.name

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
            let input: ResourceInput = self.segmented[id] {
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
            segmented: LocalMarketSnapshot?,
            tradeable: WorldMarket.State?
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
            let filled: ResourceInput = self.segmented[id],
            let market: LocalMarketSnapshot = market.segmented {
            return .instructions {
                // Show the bid price here, because the ask price is what they actually paid,
                // and that is shown several lines below
                $0["Today’s local price", -] = market.state.Δ.bid.value[..]
                $0[>] {
                    $0["Supply in this tile", +] = market.state.Δ.supply[/3]
                    $0["Demand in this tile", -] = market.state.Δ.demand[/3]
                }
                $0["Local stockpile", +] = market.state.stockpile[/3]
                $0[>] {
                    $0["Stabilization fund value", +] = market.state.stabilizationFund[/3]
                }

                if  let average: Double = filled.price,
                    let _: Int64 = market.shape.storage {
                    let spread: Double = market.state.today.spread
                    $0[>] = """
                    Due to the local bid-ask spread of \(
                        spread[%2], style: .spread(spread)
                    ), the average price they actually paid \
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
                    to decline due to their \(floor.label) of \(em: floor.price.value[..])
                    """
                } else if
                    let cap: LocalPriceLevel = market.shape.limit.max,
                        cap.price <= market.state.today.ask {
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
        case segmented = "s"
        case tradeable = "t"
    }
}
extension ResourceInputs: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.segmented] = self.segmented
        js[.tradeable] = self.tradeable
    }
}
extension ResourceInputs: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            segmented: try js[.segmented].decode(),
            tradeable: try js[.tradeable].decode(),
        )
    }
}
