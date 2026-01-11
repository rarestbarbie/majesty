import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension WorldMarket.Interval {
    @frozen public enum ObjectKey: JSString, Sendable {
        case po
        case pl
        case ph
        case pc

        case bl
        case bi
        case bo

        case ql
        case qi
        case qo
    }
}
extension WorldMarket.Interval: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.po] = self.prices.o
        js[.pl] = self.prices.l
        js[.ph] = self.prices.h
        js[.pc] = self.prices.c

        js[.bl] = self.assets.base
        js[.bi] = self.volume.base.i
        js[.bo] = self.volume.base.o
        js[.ql] = self.assets.quote
        js[.qi] = self.volume.quote.i
        js[.qo] = self.volume.quote.o
    }
}
extension WorldMarket.Interval: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            assets: .init(base: try js[.bl].decode(), quote: try js[.ql].decode()),
            volume: .init(
                base: .init(
                    i: try js[.bi].decode(),
                    o: try js[.bo].decode()
                ),
                quote: .init(
                    i: try js[.qi].decode(),
                    o: try js[.qo].decode()
                )
            ),
            prices: .init(
                o: try js[.po].decode(),
                l: try js[.pl].decode(),
                h: try js[.ph].decode(),
                c: try js[.pc].decode()
            ),
        )
    }
}
