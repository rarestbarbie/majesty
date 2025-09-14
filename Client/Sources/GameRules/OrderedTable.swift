import JavaScriptInterop
import JavaScriptKit
import OrderedCollections

@frozen @usableFromInline struct OrderedTable<Value> {
    @usableFromInline var index: OrderedDictionary<Symbol, Value>

    @inlinable init(index: OrderedDictionary<Symbol, Value>) {
        self.index = index
    }
}
extension OrderedTable: ExpressibleByDictionaryLiteral {
    @inlinable init(dictionaryLiteral: (Never, Never)...) {
        self.init(index: [:])
    }
}
extension OrderedTable: JavaScriptEncodable, ConvertibleToJSValue
    where Value: ConvertibleToJSValue & Comparable {
    @inlinable func encode(to js: inout JavaScriptEncoder<Symbol>) {
        for (symbol, id): (Symbol, Value) in self.index {
            js[symbol] = id
        }
    }
}
extension OrderedTable: JavaScriptDecodable, LoadableFromJSValue, ConstructibleFromJSValue
    where Value: LoadableFromJSValue {
    @inlinable init(from js: borrowing JavaScriptDecoder<Symbol>) throws {
        self.init(index: try js.values { .init(minimumCapacity: $0) } _: { $0[$1] = $2 })
    }
}
