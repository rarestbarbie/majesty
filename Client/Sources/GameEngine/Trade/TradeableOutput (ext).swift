import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension TradeableOutput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case quantity = "q"
        case leftover = "a"
        case proceeds = "p"
    }
}
extension TradeableOutput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.quantity] = self.quantity
        js[.leftover] = self.leftover
        js[.proceeds] = self.proceeds
    }
}
extension TradeableOutput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            quantity: try js[.quantity].decode(),
            leftover: try js[.leftover].decode(),
            proceeds: try js[.proceeds].decode()
        )
    }
}
