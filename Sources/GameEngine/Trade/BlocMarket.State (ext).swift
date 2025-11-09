import Fraction
import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension BlocMarket.State {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case b
        case q
        case dividend
        case history
        case fee
    }
}
extension BlocMarket.State: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.b] = self.capital.base
        js[.q] = self.capital.quote
        js[.dividend] = self.dividend
        js[.history] = self.history
        js[.fee] = self.fee
    }
}
extension BlocMarket.State: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            dividend: try js[.dividend].decode(),
            history: try js[.history].decode(),
            capital: .init(
                base: try js[.b].decode(),
                quote: try js[.q].decode()
            ),
            fee: try js[.fee].decode() ?? 0 %/ 1
        )
    }
}
