import DequeModule
import Fraction
import GameEconomy
import LiquidityPool

extension WorldMarketSnapshot {
    // struct Indicators {
    //     let price
    //     let v: Double
    //     let vb: Double
    //     let vq: Double
    // }
}

struct WorldMarketSnapshot: Differentiable {
    let id: WorldMarket.ID
    let dividend: Fraction
    let history: Deque<WorldMarket.Interval>
    let fee: Fraction

    let y: WorldMarket.Indicators
    let z: WorldMarket.Indicators
    let units: LiquidityPool.Assets
    let price: Candle<Double>
}
extension WorldMarketSnapshot {
    init(state: WorldMarket.State, price: Candle<Double>) {
        self.id = state.id
        self.dividend = state.dividend
        self.history = state.history
        self.fee = state.fee
        self.y = state.yesterday
        self.z = state.today
        self.units = state.units
        self.price = price
    }
}
