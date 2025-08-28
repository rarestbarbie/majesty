import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension Market {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case bl
        case bi
        case bo
        case ql
        case qi
        case qo
    }
}
extension Market: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.bl] = self.pool.assets.base
        js[.bi] = self.pool.volume.base.i
        js[.bo] = self.pool.volume.base.o
        js[.ql] = self.pool.assets.quote
        js[.qi] = self.pool.volume.quote.i
        js[.qo] = self.pool.volume.quote.o
    }
}
extension Market: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            pool: .init(
                assets: .init(base: try js[.bl].decode(), quote: try js[.ql].decode()),
                volume: .init(
                    base:  (i: try js[.bi]?.decode() ?? 0, o: try js[.bo]?.decode() ?? 0),
                    quote: (i: try js[.qi]?.decode() ?? 0, o: try js[.qo]?.decode() ?? 0)
                )
            )
        )
    }
}
