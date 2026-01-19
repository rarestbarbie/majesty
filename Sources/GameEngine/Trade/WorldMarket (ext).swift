import GameEconomy
import JavaScriptInterop

extension WorldMarket {
    var snapshot: WorldMarketSnapshot? {
        let state: WorldMarket.State = self.state
        guard
        let price: Candle<Double> = state.history.last?.prices else {
            return nil
        }

        return .init(state: state, shape: self.shape, price: price)
    }
}
