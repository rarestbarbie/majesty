import GameEconomy
import JavaScriptInterop
import JavaScriptKit
import OrderedCollections

@frozen @usableFromInline struct SymbolTable<Value> {
    @usableFromInline var index: [Symbol: Value]

    @inlinable init(index: [Symbol: Value]) {
        self.index = index
    }
}
extension SymbolTable: ExpressibleByDictionaryLiteral {
    @inlinable init(dictionaryLiteral: (Never, Never)...) {
        self.init(index: [:])
    }
}
extension SymbolTable {
    @inlinable subscript(_ symbol: Symbol) -> Value {
        get throws {
            guard let value: Value = self.index[symbol] else {
                throw SymbolResolutionError<Value>.undefined(symbol.name)
            }
            return value
        }
    }
}
extension SymbolTable where Value: Hashable {
    func resolve<Metadata>(_ table: SymbolTable<Metadata>) throws -> [Value: Metadata] {
        try table.index.reduce(into: [:]) {
            // If we got this far, we should be able to safely assume identifiers are unique.
            if let id: Value = self.index[$1.key] {
                $0[id] = $1.value
            } else {
                throw SymbolResolutionError<Value>.undefined($1.key.name)
            }
        }
    }

    func resolve<Metadata>(
        _ table: SymbolTable<Metadata>,
        wildcard: Symbol = "*",
    ) throws -> EffectsTable<Value, Metadata> {
        try table.index.reduce(into: [:]) {
            if let id: Value = self.index[$1.key] {
                $0[id] = $1.value
            } else if wildcard == $1.key {
                $0[*] = $1.value
            } else {
                throw SymbolResolutionError<Value>.undefined($1.key.name)
            }
        }
    }
}
extension SymbolTable where Value: Hashable & Comparable {
    func resolve(_ table: SymbolTable<Int64>) throws -> [Quantity<Value>] {
        var quantities: [Quantity<Value>] = try self.resolve(table).map {
            .init(amount: $1, unit: $0)
        }

        quantities.sort { $0.unit < $1.unit }
        return quantities
    }
}
extension SymbolTable where Value: RawRepresentable<Int16> & Sendable {
    /// Extends this symbol table to cover all of the symbols in the provided table.
    mutating func extend<Metadata>(
        over table: SymbolTable<Metadata>
    ) throws -> OrderedDictionary<Value, (Symbol, Metadata)> {
        /// This is required, or the assigned identifiers will not be deterministic.
        let order: [(Symbol, Metadata)] = table.index.sorted { $0.key < $1.key }
        var last: Int16 = self.index.values.reduce(into: 1) { $0 = max($0, $1.rawValue) }

        return try order.reduce(into: [:]) {
            let (symbol, metadata): (Symbol, Metadata) = $1
            let id: Value = try {
                if  let id: Value = $0 {
                    return id
                }
                if  last < .max {
                    last += 1
                } else {
                    throw AddressSpaceError<Value>.overflow
                }
                guard let id: Value = .init(rawValue: last) else {
                    throw AddressSpaceError<Value>.reserved(last)
                }

                $0 = id
                return id

            } (&self.index[symbol])

            /// We guarantee that identifiers we generate are unique, so this can only throw if
            /// a user-defined symbol has a collision with another user-defined symbol.
            try {
                if  let existing: Symbol = $0?.0 {
                    throw AddressSpaceError<Value>.collision(id, existing.name, symbol.name)
                } else {
                    $0 = (symbol, metadata)
                }
            } (&$0[id])
        }
    }
}
extension SymbolTable: JavaScriptEncodable, ConvertibleToJSValue
    where Value: ConvertibleToJSValue & Comparable {
    @inlinable func encode(to js: inout JavaScriptEncoder<Symbol>) {
        for (symbol, id): (Symbol, Value) in (self.index.sorted { $0.value < $1.value }) {
            js[symbol] = id
        }
    }
}
extension SymbolTable: JavaScriptDecodable, LoadableFromJSValue, ConstructibleFromJSValue
    where Value: LoadableFromJSValue {
    @inlinable init(from js: borrowing JavaScriptDecoder<Symbol>) throws {
        self.init(index: try js.values(as: Value.self))
    }
}
