import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension BlocMarket: JavaScriptEncodable {
    @inlinable public func encode(to js: inout JavaScriptEncoder<State.ObjectKey>) {
        self.state.encode(to: &js)
    }
}
extension BlocMarket: JavaScriptDecodable {
    @inlinable public init(from js: borrowing JavaScriptDecoder<State.ObjectKey>) throws {
        self.init(state: try .init(from: js))
    }
}
