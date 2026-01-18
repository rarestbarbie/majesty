import GameEconomy
import GameState
import JavaScriptInterop

@frozen public struct EquityStake<ID>: Identifiable, Equatable, Hashable
    where ID: Hashable & ConvertibleToJSValue & LoadableFromJSValue {
    public let id: ID
    public var shares: Reservoir
}
extension EquityStake: Sendable where ID: Sendable {}
extension EquityStake {
    init(id: ID) {
        self.init(id: id, shares: .zero)
    }

    mutating func turn() {
        self.shares.turn()
    }

    var bought: Int64 { self.shares.added }
    var sold: Int64 { self.shares.removed }
}
extension EquityStake {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case shares = "n"
        case bought = "b"
        case sold = "s"
    }
}
extension EquityStake: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.shares] = self.shares.total
        js[.bought] = self.shares.added == 0 ? nil : self.shares.added
        js[.sold] = self.shares.removed == 0 ? nil : self.shares.removed
    }
}
extension EquityStake: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            shares: .init(
                total: try js[.shares].decode(),
                added: try js[.bought]?.decode() ?? 0,
                removed: try js[.sold]?.decode() ?? 0
            )
        )
    }
}
