import GameState
import JavaScriptKit
import JavaScriptInterop

@frozen public struct EquityStake<ID>: Identifiable, Equatable, Hashable
    where ID: Hashable & ConvertibleToJSValue & LoadableFromJSValue {
    public let id: ID
    public var shares: Int64
    public var bought: Int64
    public var sold: Int64
}
extension EquityStake {
    init(id: ID) {
        self.init(id: id, shares: 0, bought: 0, sold: 0)
    }

    mutating func turn() {
        self.bought = 0
        self.sold = 0
    }
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
        js[.shares] = self.shares
        js[.bought] = self.bought == 0 ? nil : self.bought
        js[.sold] = self.sold == 0 ? nil : self.sold
    }
}
extension EquityStake: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            shares: try js[.shares].decode(),
            bought: try js[.bought]?.decode() ?? 0,
            sold: try js[.sold]?.decode() ?? 0
        )
    }
}
