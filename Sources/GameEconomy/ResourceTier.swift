import GameIDs

@frozen public struct ResourceTier: Equatable, Hashable {
    @usableFromInline let table: [Resource: Int64]
    public let x: [Quantity<Resource>]
    public let i: Int

    @inlinable init(table: [Resource: Int64], x: [Quantity<Resource>], i: Int) {
        self.table = table
        self.x = x
        self.i = i
    }
}
extension ResourceTier {
    @inlinable public static var empty: Self { .init(table: [:], x: [], i: 0) }

    @inlinable public init(segmented: [Quantity<Resource>], tradeable: [Quantity<Resource>]) {
        let array: [Quantity<Resource>] = segmented + tradeable
        let table: [Resource: Int64] = .init(
            uniqueKeysWithValues: array.lazy.map { ($0.unit, $0.amount) }
        )

        self.init(table: table, x: array, i: segmented.count)
    }
}
extension ResourceTier: RandomAccessCollection {
    @inlinable public var startIndex: Int { self.x.startIndex }
    @inlinable public var endIndex: Int { self.x.endIndex }

    @inlinable public subscript(index: Int) -> (id: Resource, amount: Int64) {
        let x: Quantity<Resource> = self.x[index]
        return (x.unit, x.amount)
    }
}
extension ResourceTier {
    @inlinable public var segmented: Coefficients { .init(x: self.x[..<self.i]) }
    @inlinable public var tradeable: Coefficients { .init(x: self.x[self.i...]) }

    @inlinable public func contains(_ resource: Resource) -> Bool {
        self.table.keys.contains(resource)
    }
    @inlinable public subscript(id: Resource) -> Int64? {
        self.table[id]
    }
}
