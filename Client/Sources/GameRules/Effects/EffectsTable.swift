@frozen public struct EffectsTable<Key, Value> where Key: Hashable {
    @usableFromInline var index: [Key?: Value]

    @inlinable init(index: [Key?: Value]) {
        self.index = index
    }
}
extension EffectsTable: Equatable where Key: Equatable, Value: Equatable {}
extension EffectsTable: Hashable where Key: Hashable, Value: Hashable {}
extension EffectsTable: Sendable where Key: Sendable, Value: Sendable {}
extension EffectsTable: ExpressibleByDictionaryLiteral {
    @inlinable public init(dictionaryLiteral: (Never, Never)...) {
        self.init(index: [:])
    }
}
extension EffectsTable {
    @inlinable public subscript(_: (EffectsWildcard, EffectsWildcard) -> ()) -> Value? {
        _read   { yield  self.index[nil] }
        _modify { yield &self.index[nil] }
    }

    @inlinable public subscript(_ key: Key) -> Value? {
        _read   { yield  self.index[key] }
        _modify { yield &self.index[key] }
    }
}
extension EffectsTable {
    @inlinable public subscript(_: (EffectsWildcard, EffectsWildcard) -> ()) -> Value {
        get throws {
            guard let value: Value = self.index[nil] else {
                throw SymbolResolutionError<Key?>.undefined("*")
            }
            return value
        }
    }
}
extension EffectsTable where Value: AdditiveArithmetic {
    @inlinable public mutating func stack(with next: Self) {
        for (key, value): (Key?, Value) in next.index {
            self.index[key, default: .zero] += value
        }
    }

    @inlinable public consuming func stacked(with next: Self) -> Self {
        self.stack(with: next)
        return self
    }
}
