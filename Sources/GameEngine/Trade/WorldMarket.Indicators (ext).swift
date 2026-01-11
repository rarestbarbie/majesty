import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension WorldMarket.Indicators {
    @frozen public enum ObjectKey: JSString, Sendable {
        case v
        case vb
        case vq
    }
}
extension WorldMarket.Indicators: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.v] = self.v
        js[.vb] = self.vb
        js[.vq] = self.vq
    }
}
extension WorldMarket.Indicators: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            v: try js[.v].decode(),
            vb: try js[.vb].decode(),
            vq: try js[.vq].decode()
        )
    }
}
