import GameState
import JavaScriptKit
import JavaScriptInterop

@frozen public struct EquityStake<Instrument>: Identifiable, Equatable, Hashable
    where Instrument: Hashable & ConvertibleToJSValue & LoadableFromJSValue {
    public let id: Instrument
    private(set) var shares: Int64
    private(set) var bought: Int64
    private(set) var sold: Int64
}
extension EquityStake {
    init(id: Instrument) {
        self.init(id: id, shares: 0, bought: 0, sold: 0)
    }

    mutating func buy(_ shares: Int64) {
        self.bought += shares
        self.shares -= shares
    }

    mutating func sell(_ shares: Int64) {
        self.sold += shares
        self.shares += shares
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
