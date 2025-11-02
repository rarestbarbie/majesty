import OrderedCollections

extension OrderedDictionary where Key == Symbol {
    func map<T>(keys: SymbolTable<T>) throws -> OrderedDictionary<T, Value> {
        try self.map(keys: keys, value: \.self)
    }
    func map<T, U>(
        keys: SymbolTable<T>,
        value: (Value) throws -> U
    ) throws -> OrderedDictionary<T, U> {
        try self.reduce(into: [:]) { $0[try keys[$1.key]] = try value($1.value) }
    }
}
