import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension InelasticInput {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case unitsDemanded = "d"
        case unitsConsumed = "c"
        case valueConsumed = "C"
        // case price = "p"
    }
}
extension InelasticInput: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.unitsDemanded] = self.unitsDemanded
        js[.unitsConsumed] = self.unitsConsumed
        js[.valueConsumed] = self.valueConsumed
        // js[.price] = self.price
    }
}
extension InelasticInput: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            unitsDemanded: try js[.unitsDemanded].decode(),
            unitsConsumed: try js[.unitsConsumed].decode(),
            valueConsumed: try js[.valueConsumed].decode(),
            // price: try js[.price].decode(),
        )
    }
}
