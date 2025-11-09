import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension LocalMarket.State {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case fp
        case ft
        case y
        case t
    }
}
extension LocalMarket.State: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.fp] = self.priceFloor?.minimum
        js[.ft] = self.priceFloor?.type
        js[.y] = self.yesterday
        js[.t] = self.today
    }
}
extension LocalMarket.State: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        let priceFloor: LocalMarket.PriceFloor?
        if  let minimum: LocalPrice = try js[.fp]?.decode() {
            priceFloor = .init(minimum: minimum, type: try js[.ft].decode())
        } else {
            priceFloor = nil
        }

        self.init(
            id: try js[.id].decode(),
            priceFloor: priceFloor,
            yesterday: try js[.y].decode(),
            today: try js[.t].decode()
        )
    }
}
