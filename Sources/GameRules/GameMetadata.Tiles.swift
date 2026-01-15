import GameIDs
import OrderedCollections

extension GameMetadata {
    @frozen public struct Tiles {
        @usableFromInline let ecology: [EcologicalType: EcologicalAttributes]
        @usableFromInline let geology: [GeologicalType: GeologicalAttributes]

        @usableFromInline var metadata: [TileType: TileMetadata]
    }
}
extension GameMetadata.Tiles {
    init(
        symbols: GameSaveSymbols,
        ecology: OrderedDictionary<SymbolAssignment<EcologicalType>, EcologicalDescription>,
        geology: OrderedDictionary<SymbolAssignment<GeologicalType>, GeologicalDescription>
    ) throws {
        let ecology: [EcologicalType: EcologicalAttributes] = ecology.map {
            EcologicalAttributes.init(identity: $0, color: $1.color)
        }
        let geology: [GeologicalType: GeologicalAttributes] = try geology.map {
            GeologicalAttributes.init(
                identity: $0,
                title: $1.title,
                base: try $1.base.map(keys: symbols.resources),
                bonus: try $1.bonus.map(keys: symbols.resources) {
                    .init(
                        weightNone: $0.weightNone,
                        weights: try $0.weights.map(keys: symbols.resources)
                    )
                },
                color: $1.color
            )
        }

        self.init(
            ecology: ecology,
            geology: geology,
            metadata: [:]
        )
    }
}
extension GameMetadata.Tiles {
    public var ecologyDefault: EcologicalType? { self.ecology.keys.min() }
    public var geologyDefault: GeologicalType? { self.geology.keys.min() }

    public var ecologyChoices: [Symbol] { self.ecology.values.map { $0.symbol } }
    public var geologyChoices: [Symbol] { self.geology.values.map { $0.symbol } }
}
extension GameMetadata.Tiles {
    @inlinable public subscript(type: TileType) -> TileMetadata? {
        mutating get {
            {
                if let existing: TileMetadata = $0 {
                    return existing
                }
                guard
                let ecology: EcologicalAttributes = self.ecology[type.ecology],
                let geology: GeologicalAttributes = self.geology[type.geology] else {
                    return nil
                }

                let new: TileMetadata = .init(
                    ecology: ecology,
                    geology: geology
                )

                $0 = new
                return new

            } (&self.metadata[type])
        }
    }
}
