import ColorText
import JavaScriptKit
import JavaScriptInterop

@frozen public struct TradingViewTick {
    let id: Int
    let price: Double
    let label: String
    let style: ColorText.Style?
}
extension TradingViewTick: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case price = "p"
        case label = "l"
        case style = "s"
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.price] = self.price
        js[.label] = self.label
        js[.style] = self.style?.id
    }
}
