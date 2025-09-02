import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension TradeableOutput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case unitsProduced = "q"
        case unitsSold = "r"
        case valueSold = "R"
        case price = "p"
    }
}
extension TradeableOutput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.unitsProduced] = self.unitsProduced
        js[.unitsSold] = self.unitsSold
        js[.valueSold] = self.valueSold
        js[.price] = self.price
    }
}
extension TradeableOutput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            unitsProduced: try js[.unitsProduced].decode(),
            unitsSold: try js[.unitsSold].decode(),
            valueSold: try js[.valueSold].decode(),
            price: try js[.price].decode()
        )
    }
}
