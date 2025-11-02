import Color
import GameIDs
import GameEconomy
import OrderedCollections

public final class PopMetadata: Identifiable, Sendable {
    public let singular: String
    public let plural: String
    public let color: Color
    public let l: ResourceTier
    public let e: ResourceTier
    public let x: ResourceTier
    public let output: ResourceTier

    private init(
        singular: String,
        plural: String,
        color: Color,
        l: ResourceTier,
        e: ResourceTier,
        x: ResourceTier,
        output: ResourceTier,
    ) {
        self.singular = singular
        self.plural = plural
        self.color = color
        self.l = l
        self.e = e
        self.x = x
        self.output = output
    }
}
extension PopMetadata {
    convenience init(
        type: PopType,
        pops: EffectsTable<PopType, PopDescription>,
        symbols: GameRules.Symbols,
        resources: OrderedDictionary<Resource, ResourceMetadata>
    ) throws {
        let pop: PopDescription? = pops[type]
        let l: SymbolTable<Int64> = try pop?.l ?? pops[*].l ?? [:]
        let e: SymbolTable<Int64> = try pop?.e ?? pops[*].e ?? [:]
        let x: SymbolTable<Int64> = try pop?.x ?? pops[*].x ?? [:]
        let output: SymbolTable<Int64> = try pop?.output ?? pops[*].output ?? [:]
        self.init(
            singular: type.singular,
            plural: type.plural,
            color: try pop?.color ?? pops[*].color ?? 0xFFFFFF,
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
