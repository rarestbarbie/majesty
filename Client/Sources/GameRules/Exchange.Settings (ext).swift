import Fraction
import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension Exchange.Settings {
    @frozen public enum ObjectKey: JSString {
        case dividend
        case fee
        case capital
        case history
    }
}
extension Exchange.Settings: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let capital: Fraction = try js[.capital].decode()
        self.init(
            dividend: try js[.dividend].decode(),
            fee: try js[.fee].decode(),
            capital: .init(base: capital.n, quote: capital.d),
            history: try js[.history].decode(),
        )
    }
}
