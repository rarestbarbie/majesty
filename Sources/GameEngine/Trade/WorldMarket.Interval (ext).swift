import GameEconomy
import JavaScriptInterop

extension WorldMarket.Interval {
    @frozen public enum ObjectKey: JSString, Sendable {
        case lb
        case lq
        case fee
        case v
        case vb
        case vq
    }
}
extension WorldMarket.Interval: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.lb] = self.assets.base
        js[.lq] = self.assets.quote
        js[.fee] = self.fee
        js[.v] = self.v
        js[.vb] = self.vb
        js[.vq] = self.vq
    }
}
extension WorldMarket.Interval: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            assets: .init(base: try js[.lb].decode(), quote: try js[.lq].decode()),
            fee: try js[.fee].decode(),
            v: try js[.v].decode(),
            vb: try js[.vb].decode(),
            vq: try js[.vq].decode()
        )
    }
}
