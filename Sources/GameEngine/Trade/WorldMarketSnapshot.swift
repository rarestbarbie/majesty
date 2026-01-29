import D
import DequeModule
import Fraction
import GameIDs
import GameEconomy
import GameUI
import LiquidityPool

struct WorldMarketSnapshot: Differentiable {
    let id: WorldMarket.ID
    let history: Deque<WorldMarket.Aggregate>

    let y: WorldMarket.Interval
    let z: WorldMarket.Interval
    let shape: WorldMarket.Shape
    let price: Candle<Double>
    let volume: LiquidityPool.Volume
}
extension WorldMarketSnapshot {
    init(state: WorldMarket.State, shape: WorldMarket.Shape, today: WorldMarket.Aggregate) {
        self.id = state.id
        self.history = state.history
        self.y = state.y
        self.z = state.z
        self.shape = shape
        self.price = today.prices
        self.volume = today.volume
    }
}
extension WorldMarketSnapshot {
    private static func takerFlow(_ volume: LiquidityPool.Volume) -> Double {
        let signed: Double =
        Double.init(volume.base.i) * Double.init(volume.quote.o) -
        Double.init(volume.quote.i) * Double.init(volume.base.o)
        return signed >= 0 ? Double.sqrt(signed) : -Double.sqrt(-signed)
    }

    private var takerFlow: Double { Self.takerFlow(self.volume) }
}
extension WorldMarketSnapshot {
    func tooltipCandle(_ date: GameDate, today: GameDate) -> Tooltip? {
        let offset: Int = today.distance(to: date)
        guard
        let index: Int = self.history.index(
            self.history.endIndex,
            offsetBy: offset - 1,
            limitedBy: self.history.startIndex
        ) else {
            return nil
        }

        let day: WorldMarket.Aggregate = self.history[index]

        return .instructions(style: .borderless, flipped: true) {
            $0[date[.phrasal_US], +] = day.prices.c[/3..3] <- day.prices.o
            $0[>] {
                $0["Low"] = day.prices.l[/3..3]
                $0["High"] = day.prices.h[/3..3]
            }
            $0["Volume"] = day.volume.base.total[/3]
            $0[>] {
                $0["Taker flow", -] = +?Self.takerFlow(day.volume)[/3..2]
            }
        }
    }

    func tooltipFee() -> Tooltip {
        .instructions {
            $0["Bid–ask spread", -] = self.Δ.fee[%2]
            $0[>] {
                $0["Base"] = self.shape.fee[%]
                $0["From trading volume", -] = +?(self.z.fee - Double.init(self.shape.fee))[%2]
            }
            let velocity: Double = self.z.velocity

            $0["Capital efficiency", -] = self.Δ.velocity[%3]
            $0[>] {
                $0["Turnover", +] = self.Δ.v[/3..2]
            }

            if  velocity < self.shape.feeBoundary {
                $0[>] = """
                Low turnover is causing market maker saturation, which is \
                \(pos: "narrowing") the bid–ask spread
                """
            } else if
                velocity > self.shape.feeBoundary {
                $0[>] = """
                High turnover is depleting market maker liquidity, which is \
                \(neg: "widening") the bid–ask spread
                """
            }
        }
    }

    func tooltipLiquidity() -> Tooltip {
        .instructions {
            $0["Available liquidity", +] = self.Δ.assets.liquidity[/3..2]
            $0[>] {
                $0["Base instrument", -] = self.Δ.assets.base[/3]
                $0["Quote instrument", +] = self.Δ.assets.quote[/3]
            }
            $0["Spoilage"] = self.shape.rot[%]
            $0[>] {
                $0["Base instrument", +] = +?self.shape.drainage(
                    assets: self.z.assets.base,
                    volume: self.z.vb
                )[%2]
                $0["Quote instrument", +] = +?self.shape.drainage(
                    assets: self.z.assets.quote,
                    volume: self.z.vq
                )[%2]
            }
        }
    }

    func tooltipPrices() -> Tooltip {
        return .instructions {
            $0["Today’s closing price", +] = self.price.c[/3..3] <- self.price.o
            $0[>] {
                $0["Open"] = self.price.o[/3..3]
                $0["Low"] = self.price.l[/3..3]
                $0["High"] = self.price.h[/3..3]
            }
            $0["Volume"] = self.volume.base.total[/3]
            $0[>] {
                $0["Taker flow", -] = +?self.takerFlow[/3..2]
            }
        }
    }

    func tooltipVolume(in context: GameUI.CacheContext) -> Tooltip {
        .instructions {
            $0["Geometric mean volume", +] = self.Δ.v[/3..2]
            $0[>] {
                $0["Today’s unit volume"] = self.volume.base.total[/3]
                let currency: String
                if  case .fiat(let id) = self.id.y {
                    currency = context.currencies[id]?.name ?? "???"
                    $0["Today’s \(currency) value"] = self.volume.quote.total[/3]
                }
            }
        }
    }

    func tooltipVelocity() -> Tooltip {
        .instructions {
            $0["Capital efficiency", -] = self.Δ.velocity[%3]
            $0[>] {
                $0["Base volume (EMA)", +] = self.Δ.vb[/3..2]
                $0["Quote volume (EMA)", +] = self.Δ.vq[/3..2]
            }
        }
    }
}
