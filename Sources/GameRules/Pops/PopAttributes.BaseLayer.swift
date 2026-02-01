import GameIDs
import GameEconomy
import OrderedCollections

extension PopAttributes {
    @frozen @usableFromInline struct BaseLayers {
        @usableFromInline var l: ResourceTier?
        @usableFromInline var e: ResourceTier?
        @usableFromInline var x: ResourceTier?
        @usableFromInline var output: ResourceTier?

        @inlinable init(
            l: ResourceTier?,
            e: ResourceTier?,
            x: ResourceTier?,
            output: ResourceTier?
        ) {
            self.l = l
            self.e = e
            self.x = x
            self.output = output
        }
    }
}
extension PopAttributes.BaseLayers {
    init(
        metadata: borrowing OrderedDictionary<Resource, ResourceMetadata>,
        l: borrowing SymbolTable<Int64>?,
        e: borrowing SymbolTable<Int64>?,
        x: borrowing SymbolTable<Int64>?,
        output: borrowing SymbolTable<Int64>?,
        symbols: borrowing SymbolTable<Resource>
    ) throws {
        self = .empty
        self.l = try l.map { try .init(metadata: metadata, quantity: $0, symbols: symbols) }
        self.e = try e.map { try .init(metadata: metadata, quantity: $0, symbols: symbols) }
        self.x = try x.map { try .init(metadata: metadata, quantity: $0, symbols: symbols) }
        self.output = try output.map {
            try .init(metadata: metadata, quantity: $0, symbols: symbols)
        }
    }
}
extension PopAttributes.BaseLayers {
    @inlinable static var empty: Self {
        .init(
            l: nil,
            e: nil,
            x: nil,
            output: nil
        )
    }
}
extension PopAttributes.BaseLayers {
    static func |= (self: inout Self, next: Self) {
        self.l = next.l ?? self.l
        self.e = next.e ?? self.e
        self.x = next.x ?? self.x
        self.output = next.output ?? self.output
    }
}
