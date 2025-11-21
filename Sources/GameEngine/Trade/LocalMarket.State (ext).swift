import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension LocalMarket.State {
    var Δ: TurnDelta<LocalMarket.Interval> {
        .init(y: self.yesterday, z: self.today)
    }
}
extension LocalMarket.State {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case f
        case q
        case qi
        case qo
        case b
        case bi
        case bo
        case y
        case t
    }
}
extension LocalMarket.State: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.f] = self.stabilizationFundFees
        js[.q] = self.stabilizationFund.total
        js[.qi] = self.stabilizationFund.added
        js[.qo] = self.stabilizationFund.removed
        js[.b] = self.stockpile.total
        js[.bi] = self.stockpile.added
        js[.bo] = self.stockpile.removed
        js[.y] = self.yesterday
        js[.t] = self.today
    }
}
extension LocalMarket.State: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            stabilizationFundFees: try js[.f].decode(),
            stabilizationFund: .init(
                total: try js[.q].decode(),
                added: try js[.qi].decode(),
                removed: try js[.qo].decode()
            ),
            stockpile: .init(
                total: try js[.b].decode(),
                added: try js[.bi].decode(),
                removed: try js[.bo].decode()
            ),
            yesterday: try js[.y].decode(),
            today: try js[.t].decode(),
        )
    }
}
