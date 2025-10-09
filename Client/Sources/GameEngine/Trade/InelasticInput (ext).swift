import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension InelasticInput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case unitsAcquired = "a"
        case unitsConsumed = "c"
        case unitsDemanded = "d"
        case unitsPurchased = "b"
        case valueAcquired = "A"
        case valueConsumed = "C"
    }
}
extension InelasticInput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.unitsAcquired] = self.unitsAcquired
        js[.unitsConsumed] = self.unitsConsumed
        js[.unitsDemanded] = self.unitsDemanded
        js[.unitsPurchased] = self.unitsPurchased
        js[.valueAcquired] = self.valueAcquired
        js[.valueConsumed] = self.valueConsumed
    }
}
extension InelasticInput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            unitsAcquired: try js[.unitsAcquired].decode(),
            unitsConsumed: try js[.unitsConsumed].decode(),
            unitsDemanded: try js[.unitsDemanded].decode(),
            unitsPurchased: try js[.unitsPurchased].decode(),
            valueAcquired: try js[.valueAcquired].decode(),
            valueConsumed: try js[.valueConsumed].decode(),
        )
    }
}
