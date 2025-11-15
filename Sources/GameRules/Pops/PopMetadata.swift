import Color
import GameIDs
import GameEconomy
import OrderedCollections

public final class PopMetadata: Identifiable, Sendable {
    public let id: PopType
    public let color: Color
    public let l: ResourceTier
    public let e: ResourceTier
    public let x: ResourceTier
    public let output: ResourceTier

    private init(
        id: PopType,
        color: Color,
        l: ResourceTier,
        e: ResourceTier,
        x: ResourceTier,
        output: ResourceTier,
    ) {
        self.id = id
        self.color = color
        self.l = l
        self.e = e
        self.x = x
        self.output = output
    }
}
extension PopMetadata {
    convenience init(
        id: PopType,
        effects: EffectsTable<PopType, PopDescription>,
        symbols: GameSaveSymbols,
        resources: OrderedDictionary<Resource, ResourceMetadata>
    ) throws {
        let pop: PopDescription? = effects[id]
        let l: SymbolTable<Int64> = try pop?.l ?? effects[*].l ?? [:]
        let e: SymbolTable<Int64> = try pop?.e ?? effects[*].e ?? [:]
        let x: SymbolTable<Int64> = try pop?.x ?? effects[*].x ?? [:]
        let output: SymbolTable<Int64> = try pop?.output ?? effects[*].output ?? [:]
        self.init(
            id: id,
            color: try pop?.color ?? effects[*].color ?? 0xFFFFFF,
            l: .init(metadata: resources, quantity: try l.quantities(keys: symbols.resources)),
            e: .init(metadata: resources, quantity: try e.quantities(keys: symbols.resources)),
            x: .init(metadata: resources, quantity: try x.quantities(keys: symbols.resources)),
            output: .init(
                metadata: resources,
                quantity: try output.quantities(keys: symbols.resources)
            )
        )
    }
}
extension PopMetadata {
    @inlinable public var singular: String { self.id.singular }
    @inlinable public var plural: String { self.id.plural }
}
extension PopMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.singular.hash(into: &hasher)
        self.plural.hash(into: &hasher)
        self.color.hash(into: &hasher)
        self.l.hash(into: &hasher)
        self.e.hash(into: &hasher)
        self.x.hash(into: &hasher)
        self.output.hash(into: &hasher)

        return hasher.finalize()
    }
}
