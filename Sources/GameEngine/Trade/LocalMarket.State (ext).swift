import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension LocalMarket.State {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case min_price = "fp"
        case min_label = "ft"
        case max_price = "gp"
        case max_label = "gt"
        case y
        case t
    }
}
extension LocalMarket.State: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.min_price] = self.limit.min?.price
        js[.min_label] = self.limit.min?.label
        js[.max_price] = self.limit.max?.price
        js[.max_label] = self.limit.max?.label
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
            yesterday: try js[.y].decode(),
            today: try js[.t].decode(),
            limit: (min: min, max: max)
        )
    }
}
