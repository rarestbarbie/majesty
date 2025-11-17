import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension LocalMarket.State {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case q
        case qi
        case qo
        case b
        case bi
        case bo
        case min_price = "fp"
        case min_label = "ft"
        case max_price = "gp"
        case max_label = "gt"
        case storage = "s"
        case y
        case t
    }
}
extension LocalMarket.State: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.q] = self.stabilizationFund.total
        js[.qi] = self.stabilizationFund.added
        js[.qo] = self.stabilizationFund.removed
        js[.b] = self.stockpile.total
        js[.bi] = self.stockpile.added
        js[.bo] = self.stockpile.removed
        js[.min_price] = self.limit.min?.price
        js[.min_label] = self.limit.min?.label
        js[.max_price] = self.limit.max?.price
        js[.max_label] = self.limit.max?.label
        js[.storage] = self.storage ? true : nil
        js[.y] = self.yesterday
        js[.t] = self.today
    }
}
extension LocalMarket.State: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let min: LocalPriceLevel?
        let max: LocalPriceLevel?

        if  let price: LocalPrice = try js[.min_price]?.decode() {
            min = .init(price: price, label: try js[.min_label].decode())
        } else {
            min = nil
        }
        if  let price: LocalPrice = try js[.max_price]?.decode() {
            max = .init(price: price, label: try js[.max_label].decode())
        } else {
            max = nil
        }

        self.init(
            id: try js[.id].decode(),
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
            limit: (min: min, max: max),
            storage: try js[.storage]?.decode() ?? false
        )
    }
}
