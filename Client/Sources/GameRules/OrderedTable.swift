import JavaScriptInterop
import JavaScriptKit
import OrderedCollections

struct OrderedTable<Value> {
    let index: OrderedDictionary<Symbol, Value>

    init(index: OrderedDictionary<Symbol, Value>) {
        self.index = index
    }
}
extension OrderedTable: JavaScriptEncodable, ConvertibleToJSValue
    where Value: ConvertibleToJSValue & Comparable {
    func encode(to js: inout JavaScriptEncoder<Symbol>) {
        for (symbol, id): (Symbol, Value) in self.index {
            js[symbol] = id
        }
    }
}
extension OrderedTable: JavaScriptDecodable, LoadableFromJSValue, ConstructibleFromJSValue
    where Value: LoadableFromJSValue {
    init(from js: borrowing JavaScriptDecoder<Symbol>) throws {
        self.init(index: try js.values { .init(minimumCapacity: $0) } combine: { $0[$1] = $2 })
    }
}
