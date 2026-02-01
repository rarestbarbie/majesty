import GameEconomy
import GameIDs
import OrderedCollections

extension ResourceTier {
    init(
        metadata: borrowing OrderedDictionary<Resource, ResourceMetadata>,
        quantity: borrowing SymbolTable<Int64>,
        symbols: borrowing SymbolTable<Resource>
    ) throws {
        self.init(
            stacking: try .init(metadata: metadata, quantity: quantity, symbols: symbols)
        )
    }

    init(stacking layer: PopAttributes.StackingLayer) {
        self.init(
            segmented: Self.stack(layer.segmented),
            tradeable: Self.stack(layer.tradeable)
        )
    }

    private static func stack(
        _ quantities: consuming [Quantity<Resource>]
    ) -> [Quantity<Resource>] {
        let total: [Resource: Int64] = quantities.reduce(into: [:]) {
            $0[$1.unit, default: 0] += $1.amount
        }
        var stacked: [Quantity<Resource>] = total.map { .init(amount: $1, unit: $0) }
        stacked.sort { $0.unit < $1.unit }
        return stacked
    }
}
