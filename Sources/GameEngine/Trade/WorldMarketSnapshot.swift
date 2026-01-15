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
    let price: Candle<Double>
    let shape: WorldMarket.Shape
}
extension WorldMarketSnapshot {
    init(state: WorldMarket.State, shape: WorldMarket.Shape, price: Candle<Double>) {
        self.id = state.id
        self.history = state.history
        self.y = state.y
        self.z = state.z
        self.price = price
        self.shape = shape
    }
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
                let signed: Double =
                Double.init(day.volume.base.i) * Double.init(day.volume.quote.o) -
                Double.init(day.volume.quote.i) * Double.init(day.volume.base.o)

                $0["Taker flow", -] = +?(
                    signed >= 0 ? Double.sqrt(signed) : -Double.sqrt(-signed)
                )[/3..2]
            }
        }
    }

    func tooltipLiquidity() -> Tooltip? {
        return .instructions {
            $0["Available liquidity", +] = self.Δ.assets.liquidity[/3..2]
            $0[>] {
                $0["Base instrument", -] = self.Δ.assets.base[/3]
                $0["Quote instrument", +] = self.Δ.assets.quote[/3]
            }

            $0["Capital efficiency", -] = self.Δ.velocity[%3]
            $0[>] {
                $0["Base volume (EMA)", +] = self.Δ.vb[/3..2]
                $0["Quote volume (EMA)", +] = self.Δ.vq[/3..2]
            }
            // TODO: should be moved to separate tooltip
            $0["Spoilage"] = self.shape.rot[%2]
            $0[>] {
                let b: Double = max(1, Double.init(self.z.assets.base))
                let q: Double = max(1, Double.init(self.z.assets.quote))
                $0["Base instrument", +] = ??(
                    self.shape.rot * min(0, self.z.vb * self.shape.depth - b) / b
                )[%2]
                $0["Quote instrument", +] = ??(
                    self.shape.rot * min(0, self.z.vq * self.shape.depth - q) / q
                )[%2]
            }
        }
    }
}
