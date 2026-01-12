import DequeModule
import Fraction
import GameEconomy
import LiquidityPool

struct WorldMarketSnapshot: Differentiable {
    let id: WorldMarket.ID
    let dividend: Fraction
    let history: Deque<WorldMarket.Aggregate>
    let fee: Fraction

    let y: WorldMarket.Interval
    let z: WorldMarket.Interval
    let price: Candle<Double>
}
extension WorldMarketSnapshot {
    init(state: WorldMarket.State, price: Candle<Double>) {
        self.id = state.id
        self.dividend = state.dividend
        self.history = state.history
        self.fee = state.fee
        self.y = state.y
        self.z = state.z
        self.price = price
    }
}
