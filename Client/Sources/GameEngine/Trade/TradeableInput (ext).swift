import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension TradeableInput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case unitsAcquired = "a"
        case unitsConsumed = "c"
        case unitsDemanded = "d"

        case valueAcquired = "A"
        case valueConsumed = "C"

        case unitsPurchased = "b"
        case unitsReturned = "r"
        case price = "p"
    }
}
extension TradeableInput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.unitsAcquired] = self.unitsAcquired
        js[.unitsDemanded] = self.unitsDemanded
        js[.unitsConsumed] = self.unitsConsumed
        js[.unitsPurchased] = self.unitsPurchased
        js[.unitsReturned] = self.unitsReturned
        js[.valueAcquired] = self.valueAcquired
        js[.valueConsumed] = self.valueConsumed
        js[.price] = self.price
    }
}
extension TradeableInput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            unitsAcquired: try js[.unitsAcquired].decode(),
            unitsConsumed: try js[.unitsConsumed].decode(),
            unitsDemanded: try js[.unitsDemanded].decode(),
            unitsPurchased: try js[.unitsPurchased].decode(),
            unitsReturned: try js[.unitsReturned].decode(),
            valueAcquired: try js[.valueAcquired].decode(),
            valueConsumed: try js[.valueConsumed].decode(),
            price: try js[.price].decode()
        )
    }
}
