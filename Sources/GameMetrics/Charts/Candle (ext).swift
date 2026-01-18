import GameEconomy
import JavaScriptInterop
import RealModule

extension Candle<Double> {
    @inlinable public var log10: Self {
        .init(
            o: Double.log10(self.o),
            l: Double.log10(self.l),
            h: Double.log10(self.h),
            c: Double.log10(self.c)
        )
    }
}
extension Candle {
    @frozen public enum ObjectKey: JSString, Sendable {
        case o
        case l
        case h
        case c
    }
}
extension Candle: JavaScriptEncodable, ConvertibleToJSValue
    where Price: ConvertibleToJSValue {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.o] = self.o
        js[.l] = self.l
        js[.h] = self.h
        js[.c] = self.c
    }
}
extension Candle: JavaScriptDecodable, LoadableFromJSValue, ConstructibleFromJSValue
    where Price: LoadableFromJSValue {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            o: try js[.o].decode(),
            l: try js[.l].decode(),
            h: try js[.h].decode(),
            c: try js[.c].decode()
        )
    }
}
