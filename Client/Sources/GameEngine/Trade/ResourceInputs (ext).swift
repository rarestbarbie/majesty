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

        let consumed: Int64
        let demanded: Int64

        if  let input: TradeableInput = self.tradeable[id] {
            consumed = input.unitsConsumed
            demanded = input.unitsDemanded
        } else if
            let input: InelasticInput = self.inelastic[id] {
            consumed = input.unitsConsumed
            demanded = input.unitsDemanded
        } else {
            return nil
        }

        return .instructions {
            $0["Consumed today", +] = consumed[/3] / demanded
            $0[>] {
                $0["Demand per \(unit)"] = (factor * Double.init(amount))[..3]
            }
        }
    }

    func tooltipStockpile(_ id: Resource) -> Tooltip? {
        if  let stock: TradeableInput = self.tradeable[id] {
            return .instructions {
                let change: Int64 = stock.unitsPurchased - stock.unitsConsumed

                $0["Total stockpile", +] = stock.unitsAcquired[/3] <- stock.unitsAcquired - change
                $0[>] {
                    $0["Average cost"] = ??stock.averageCost[..2]
                    $0["Supply (days)"] = stock.unitsAcquired == 0
                        ? nil
                        : (Double.init(stock.unitsAcquired) / Double.init(stock.unitsDemanded))[..3]
                }

                $0["Purchased today", +] = +?stock.unitsPurchased[/3]
            }
        } else {
            return nil
        }
    }

    func tooltipExplainPrice(
        _ id: Resource,
        _ price: Candle<Double>,
    ) -> Tooltip? {
        if  let actual: TradeableInput = self.tradeable[id] {
            return .instructions {
                $0["Today’s closing price", -] = price.c[..2] <- price.o
                $0[>] = actual.price == price.c ? nil : """
                Due to their position in line, and the available liquidity on the market, the \
                average price they actually paid today was \(em: actual.price[..2])
                """
                $0[>] = actual.price <= price.l ? nil : """
                The luckiest buyers paid \(em: price.l[..2]) today
                """
            }
        } else if
            let _: InelasticInput = self.inelastic[id] {
            return nil
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
