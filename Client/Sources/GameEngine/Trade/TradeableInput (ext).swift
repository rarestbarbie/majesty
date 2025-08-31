import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension TradeableInput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case acquiredValue = "A"
        case acquired = "a"
        case capacity = "s"
        case demanded = "d"
        case consumedValue = "C"
        case consumed = "c"
        case purchased = "b"
        case price = "p"
    }
}
extension TradeableInput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.acquiredValue] = self.acquiredValue
        js[.acquired] = self.acquired
        js[.capacity] = self.capacity
        js[.demanded] = self.demanded
        js[.consumedValue] = self.consumedValue
        js[.consumed] = self.consumed
        js[.purchased] = self.purchased
        js[.price] = self.price
    }
}
extension TradeableInput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            acquiredValue: try js[.acquiredValue].decode(),
            acquired: try js[.acquired].decode(),
            capacity: try js[.capacity].decode(),
            demanded: try js[.demanded].decode(),
            consumedValue: try js[.consumedValue].decode(),
            consumed: try js[.consumed].decode(),
            purchased: try js[.purchased].decode(),
            price: try js[.price].decode()
        )
    }
}
