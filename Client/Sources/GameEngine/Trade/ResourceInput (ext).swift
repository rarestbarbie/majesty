import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension ResourceInput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case acquiredValue = "A"
        case acquired = "a"
        case capacity = "s"
        case demanded = "d"

        case consumed = "c"
        case purchased = "b"
    }
}
extension ResourceInput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.acquiredValue] = self.acquiredValue
        js[.acquired] = self.acquired
        js[.capacity] = self.capacity
        js[.demanded] = self.demanded
        js[.consumed] = self.consumed
        js[.purchased] = self.purchased
    }
}
extension ResourceInput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            acquiredValue: try js[.acquiredValue].decode(),
            acquired: try js[.acquired].decode(),
            capacity: try js[.capacity].decode(),
            demanded: try js[.demanded].decode(),
            consumed: try js[.consumed].decode(),
            purchased: try js[.purchased].decode(),
        )
    }
}
