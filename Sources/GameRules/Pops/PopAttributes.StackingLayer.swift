import GameIDs
import GameEconomy
import OrderedCollections

extension PopAttributes {
    @frozen @usableFromInline struct StackingLayer {
        @usableFromInline var segmented: [Quantity<Resource>]
        @usableFromInline var tradeable: [Quantity<Resource>]

        @inlinable init(
            segmented: [Quantity<Resource>],
            tradeable: [Quantity<Resource>]
        ) {
            self.segmented = segmented
            self.tradeable = tradeable
        }
    }
}
extension PopAttributes.StackingLayer {
    init(
        metadata: borrowing OrderedDictionary<Resource, ResourceMetadata>,
        quantity: borrowing SymbolTable<Int64>,
        symbols: borrowing SymbolTable<Resource>
    ) throws {
        self.init(metadata: metadata, quantity: try quantity.quantities(keys: symbols))
    }

    private init(
        metadata: borrowing OrderedDictionary<Resource, ResourceMetadata>,
        quantity: borrowing [Quantity<Resource>],
    ) {
        let x: (
            segmented: [Quantity<Resource>],
            tradeable: [Quantity<Resource>],
        ) = quantity.reduce(into: ([], [])) {
            if case true? = metadata[$1.unit]?.local {
                $0.segmented.append($1)
            } else {
                $0.tradeable.append($1)
            }
        }

        self.init(segmented: x.segmented, tradeable: x.tradeable)
    }
}
extension PopAttributes.StackingLayer {
    @inlinable static var empty: Self {
        .init(segmented: [], tradeable: [])
    }
}
extension PopAttributes.StackingLayer {
    static func |= (self: inout Self, next: Self) {
        self.segmented += next.segmented
        self.tradeable += next.tradeable
    }

    static func | (base: ResourceTier?, self: consuming Self) -> ResourceTier {
        if  let base: ResourceTier {
            self.segmented += base.segmented.x
            self.tradeable += base.tradeable.x
        }
        return .init(stacking: self)
    }
}
