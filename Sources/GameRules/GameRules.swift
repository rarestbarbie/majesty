import Color
import GameEconomy
import GameIDs
import OrderedCollections

@frozen public struct GameRules {
    public let resources: OrderedDictionary<Resource, ResourceMetadata>
    public let factories: OrderedDictionary<FactoryType, FactoryMetadata>
    public let mines: OrderedDictionary<MineType, MineMetadata>
    public let technologies: OrderedDictionary<Technology, TechnologyMetadata>
    public let geology: OrderedDictionary<GeologicalType, GeologicalMetadata>
    public let terrains: OrderedDictionary<TerrainType, TerrainMetadata>

    public let pops: [PopType: PopMetadata]

    public let settings: Settings

    @inlinable public init(
        resources: OrderedDictionary<Resource, ResourceMetadata>,
        factories: OrderedDictionary<FactoryType, FactoryMetadata>,
        mines: OrderedDictionary<MineType, MineMetadata>,
        technologies: OrderedDictionary<Technology, TechnologyMetadata>,
        geology: OrderedDictionary<GeologicalType, GeologicalMetadata>,
        terrains: OrderedDictionary<TerrainType, TerrainMetadata>,
        pops: [PopType: PopMetadata],
        settings: Settings
    ) {
        self.resources = resources
        self.factories = factories
        self.mines = mines
        self.technologies = technologies
        self.geology = geology
        self.terrains = terrains
        self.pops = pops
        self.settings = settings
    }
}
extension GameRules {
    private typealias Tables = (
        resources: OrderedDictionary<SymbolAssignment<Resource>, ResourceDescription>,
        factories: OrderedDictionary<SymbolAssignment<FactoryType>, FactoryDescription>,
        mines: OrderedDictionary<SymbolAssignment<MineType>, MineDescription>,
        technologies: OrderedDictionary<SymbolAssignment<Technology>, TechnologyDescription>,
        geology: OrderedDictionary<SymbolAssignment<GeologicalType>, GeologicalDescription>,
        terrains: OrderedDictionary<SymbolAssignment<TerrainType>, TerrainDescription>
    )
}
extension GameRules {
    public init(
        resolving rules: borrowing GameRulesDescription,
        with symbols: inout GameSaveSymbols
    ) throws {
        try self.init(
            resolving: rules,
            table: (
                try symbols.resources.extend(over: rules.resources),
                try symbols.factories.extend(over: rules.factories),
                try symbols.mines.extend(over: rules.mines),
                try symbols.technologies.extend(over: rules.technologies),
                try symbols.geology.extend(over: rules.geology),
                try symbols.terrains.extend(over: rules.terrains),
            ),
            symbols: symbols,
            settings: .init(
                exchange: rules.exchange
            )
        )
    }

    /// It is critical here that `symbols` is the last parameter, because Swift evaluates
    /// function arguments from left to right.
    private init(
        resolving rules: borrowing GameRulesDescription,
        table: Tables,
        symbols: GameSaveSymbols,
        settings: Settings
    ) throws {
        let pops: EffectsTable<PopType, PopDescription> = try rules.pops.effects(
            keys: symbols.pops,
            wildcard: "*"
        )
        let resources: OrderedDictionary<Resource, ResourceMetadata> = table.resources.map {
            .init(
                identity: $0,
                color: $1.color,
                emoji: $1.emoji,
                local: $1.local ?? false,
                storable: $1.storable ?? false,
                hours: $1.hours
            )
        }

        let factoryCosts: EffectsTable<
            FactoryType,
            SymbolTable<Int64>
        > = try rules.factoryCosts.construction.effects(keys: symbols.factories, wildcard: "*")

        self.init(
            resources: resources,
            factories: try table.factories.map {
                return try .init(
                    identity: $0,
                    inputs: .init(
                        metadata: resources,
                        quantity: try $1.inputs.quantities(keys: symbols.resources)
                    ),
                    office: .init(
                        metadata: resources,
                        quantity: try $1.office.quantities(keys: symbols.resources)
                    ),
                    costs: .init(
                        metadata: resources,
                        quantity: try (try factoryCosts[$0.code] ?? factoryCosts[*]).quantities(
                            keys: symbols.resources
                        )
                    ),
                    output: .init(
                        metadata: resources,
                        quantity: try $1.output.quantities(keys: symbols.resources)
                    ),
                    workers: try $1.workers.quantities(keys: symbols.pops),
                    sharesInitial: rules.factoryCosts.sharesInitial,
                    sharesPerLevel: rules.factoryCosts.sharesPerLevel,
                    terrainAllowed: .init(
                        try $1.terrain.lazy.map { try symbols.terrains[$0] }
                    )
                )
            },
            mines: try table.mines.map {
                .init(
                    identity: $0,
                    base: .init(
                        metadata: resources,
                        quantity: try $1.base.quantities(keys: symbols.resources)
                    ),
                    miner: try symbols.pops[$1.miner],
                    decay: $1.decay,
                    scale: $1.scale,
                    spawn: try $1.spawn.map(keys: symbols.geology),
                )
            },
            technologies: try table.technologies.map {
                try .init(
                    identity: $0 as SymbolAssignment<Technology>,
                    starter: $1.starter,
                    effects: try $1.effects.resolved(with: symbols),
                    summary: $1.summary
                )
            },
            geology: try table.geology.map {
                .init(
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
            },
            terrains: table.terrains.map {
                .init(identity: $0, color: $1.color)
            },
            pops: try PopType.allCases.map(to: [PopType: PopMetadata].self) {
                try .init(id: $0, effects: pops, symbols: symbols, resources: resources)
            },
            settings: settings
        )
    }
}
extension GameRules {
    /// Compute a slow hash of the game rules, used for checking mod compatibility.
    public var hash: Int {
        var hasher: Hasher = .init()

        // TODO: hash settings

        for value: ResourceMetadata in self.resources.values {
            value.hash.hash(into: &hasher)
        }
        for value: FactoryMetadata in self.factories.values {
            value.hash.hash(into: &hasher)
        }
        for (key, value): (MineType, MineMetadata) in self.mines {
            key.hash(into: &hasher)
            value.hash.hash(into: &hasher)
        }
        for (key, value): (Technology, TechnologyMetadata) in self.technologies {
            key.hash(into: &hasher)
            value.hash.hash(into: &hasher)
        }
        for (key, value): (GeologicalType, GeologicalMetadata) in self.geology {
            key.hash(into: &hasher)
            value.hash.hash(into: &hasher)
        }
        for (key, value): (TerrainType, TerrainMetadata) in self.terrains {
            key.hash(into: &hasher)
            value.hash.hash(into: &hasher)
        }
        for (key, value): (PopType, PopMetadata) in self.pops.sorted(by: { $0.key < $1.key }) {
            key.hash(into: &hasher)
            value.hash.hash(into: &hasher)
        }

        return hasher.finalize()
    }
}
