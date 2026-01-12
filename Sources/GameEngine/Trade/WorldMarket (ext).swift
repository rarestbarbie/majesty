import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension WorldMarket {
    var snapshot: WorldMarketSnapshot? {
        let state: WorldMarket.State = self.state
        guard
        let price: Candle<Double> = state.history.last?.prices else {
            return nil
        }

        return .init(state: state, price: price)
    }
}
extension WorldMarket: JavaScriptEncodable {
    @inlinable public func encode(to js: inout JavaScriptEncoder<State.ObjectKey>) {
        self.state.encode(to: &js)
    }
}
extension WorldMarket: JavaScriptDecodable {
    @inlinable public init(from js: borrowing JavaScriptDecoder<State.ObjectKey>) throws {
        self.init(state: try .init(from: js))
    }
}
