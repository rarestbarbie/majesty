import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension LocalMarket {
    func snapshot(_ region: RegionalProperties) -> LocalMarketSnapshot {
        .init(
            state: self.state,
            policy: region.modifiers.localMarkets[self.id.resource] ?? .default
        )
    }
}
extension LocalMarket: JavaScriptEncodable {
    @inlinable public func encode(to js: inout JavaScriptEncoder<State.ObjectKey>) {
        self.state.encode(to: &js)
    }
}
extension LocalMarket: JavaScriptDecodable {
    @inlinable public init(from js: borrowing JavaScriptDecoder<State.ObjectKey>) throws {
        self.init(state: try .init(from: js))
    }
}
