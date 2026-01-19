import D
import JavaScriptInterop

@frozen public struct GeologicalSpawnWeight: Equatable {
    public let chance: Int64
    public let amount: Decimal
}
extension GeologicalSpawnWeight: Hashable {
    /// Manual implementation needed because ``Decimal`` does not conform to ``Hashable``.
    /// This means the number of decimal places in ``amount`` is significant for hashing.
    public func hash(into hasher: inout Hasher) {
        self.chance.hash(into: &hasher)
        self.amount.power.hash(into: &hasher)
        self.amount.units.hash(into: &hasher)
    }
}
extension GeologicalSpawnWeight: JavaScriptDecodable {
    @frozen public enum ObjectKey: JSString {
        case chance
        case amount
    }

    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            chance: try js[.chance].decode(),
            amount: try js[.amount]?.decode() ?? 0
        )
    }
}
