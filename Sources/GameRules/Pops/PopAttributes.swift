import Color
import GameIDs
import GameEconomy
import OrderedCollections

@frozen @usableFromInline struct PopAttributes {
    @usableFromInline var base: BaseLayers
    @usableFromInline var l: StackingLayer
    @usableFromInline var e: StackingLayer
    @usableFromInline var x: StackingLayer
    @usableFromInline var output: StackingLayer

    @inlinable init(
        base: BaseLayers,
        l: StackingLayer,
        e: StackingLayer,
        x: StackingLayer,
        output: StackingLayer
    ) {
        self.base = base
        self.l = l
        self.e = e
        self.x = x
        self.output = output
    }
}
extension PopAttributes {
    init(
        metadata: borrowing OrderedDictionary<Resource, ResourceMetadata>,
        decoding description: borrowing PopAttributesDescription,
        symbols: borrowing SymbolTable<Resource>
    ) throws {
        self = try .init(
            metadata: metadata,
            base: description.base,
            plus: description.plus,
            symbols: symbols
        )
    }

    private init(
        metadata: borrowing OrderedDictionary<Resource, ResourceMetadata>,
        base: __shared (
            l: SymbolTable<Int64>?,
            e: SymbolTable<Int64>?,
            x: SymbolTable<Int64>?,
            output: SymbolTable<Int64>?,
        ),
        plus: __shared (
            l: SymbolTable<Int64>?,
            e: SymbolTable<Int64>?,
            x: SymbolTable<Int64>?,
            output: SymbolTable<Int64>?,
        ),
        symbols: borrowing SymbolTable<Resource>
    ) throws {
        self = .empty

        self.base = try .init(
            metadata: metadata,
            l: base.l,
            e: base.e,
            x: base.x,
            output: base.output,
            symbols: symbols
        )

        if  let layer: SymbolTable<Int64> = plus.l {
            self.l = try .init(metadata: metadata, quantity: layer, symbols: symbols)
        }
        if  let layer: SymbolTable<Int64> = plus.e {
            self.e = try .init(metadata: metadata, quantity: layer, symbols: symbols)
        }
        if  let layer: SymbolTable<Int64> = plus.x {
            self.x = try .init(metadata: metadata, quantity: layer, symbols: symbols)
        }
        if  let layer: SymbolTable<Int64> = plus.output {
            self.output = try .init(metadata: metadata, quantity: layer, symbols: symbols)
        }
    }

    @inlinable static var empty: PopAttributes {
        .init(
            base: .empty,
            l: .empty,
            e: .empty,
            x: .empty,
            output: .empty
        )
    }
}
extension PopAttributes {
    static func |= (self: inout Self, next: Self) {
        self.base |= next.base
        self.l |= next.l
        self.e |= next.e
        self.x |= next.x
        self.output |= next.output
    }
}
