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
        case dividend
        case fee
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
        js[.dividend] = self.dividend
        js[.fee] = self.pool.fee
    }
}
extension Market: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            dividend: try js[.dividend].decode(),
            pool: .init(
                assets: .init(base: try js[.bl].decode(), quote: try js[.ql].decode()),
                volume: .init(
                    base: .init(i: try js[.bi].decode(), o: try js[.bo].decode()),
                    quote: .init(i: try js[.qi].decode(), o: try js[.qo].decode()),
                ),
                fee: try js[.fee].decode() ?? 0 %/ 1
            )
        )
    }
}
