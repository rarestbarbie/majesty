import Fraction
import GameEconomy
import JavaScriptInterop

extension WorldMarkets.Settings {
    @frozen public enum ObjectKey: JSString {
        case depth
        case rot
        case fee
        case capital
        case history
    }
}
extension WorldMarkets.Settings: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let capital: Fraction = try js[.capital].decode()
        self.init(
            depth: try js[.depth].decode(),
            rot: try js[.rot].decode(),
            fee: try js[.fee].decode(),
            capital: .init(base: capital.n, quote: capital.d),
            history: try js[.history].decode(),
        )
    }
}
