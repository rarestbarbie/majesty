import GameEconomy
import JavaScriptInterop

extension WorldMarket {
    var snapshot: WorldMarketSnapshot? {
        let state: WorldMarket.State = self.state
        guard
        let today: Aggregate = state.history.last else {
            return nil
        }

        return .init(state: state, shape: self.shape, today: today)
    }
}
