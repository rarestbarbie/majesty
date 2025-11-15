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
        resources: OrderedDictionary<Resource, (Symbol, ResourceDescription)>,
        factories: OrderedDictionary<FactoryType, (Symbol, FactoryDescription)>,
        mines: OrderedDictionary<MineType, (Symbol, MineDescription)>,
        technologies: OrderedDictionary<Technology, (Symbol, TechnologyDescription)>,
        geology: OrderedDictionary<GeologicalType, (Symbol, GeologicalDescription)>,
        terrains: OrderedDictionary<TerrainType, (Symbol, TerrainDescription)>
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
        let resources: OrderedDictionary<
            Resource,
            ResourceMetadata
        > = table.resources.mapValues {
            .init(
                name: $0.name,
                color: $1.color,
                emoji: $1.emoji,
                local: $1.local,
                hours: $1.hours
            )
        }

        let factoryCosts: EffectsTable<
            FactoryType,
            SymbolTable<Int64>
        > = try rules.factoryCosts.construction.effects(keys: symbols.factories, wildcard: "*")

        self.init(
            resources: resources,
            factories: try table.factories.reduce(
                into: [:]
            ) {
                let (type, (symbol, factory)): (FactoryType, (Symbol, FactoryDescription)) = $1
                $0[type] = try .init(
                    name: symbol.name,
                    inputs: .init(
                        metadata: resources,
                        quantity: try factory.inputs.quantities(keys: symbols.resources)
                    ),
                    office: .init(
                        metadata: resources,
                        quantity: try factory.office.quantities(keys: symbols.resources)
                    ),
                    costs: .init(
                        metadata: resources,
                        quantity: try (try factoryCosts[type] ?? factoryCosts[*]).quantities(keys: symbols.resources)
                    ),
                    output: .init(
                        metadata: resources,
                        quantity: try factory.output.quantities(keys: symbols.resources)
                    ),
                    workers: try factory.workers.quantities(keys: symbols.pops),
                    sharesInitial: rules.factoryCosts.sharesInitial,
                    sharesPerLevel: rules.factoryCosts.sharesPerLevel,
                    terrainAllowed: .init(
                        try factory.terrain.lazy.map { try symbols.terrains[$0] }
                    )
                )
            },
            mines: try table.mines.reduce(into: [:]) {
                let (type, (symbol, mine)): (MineType, (Symbol, MineDescription)) = $1

                $0[type] = MineMetadata.init(
                    name: symbol.name,
                    base: .init(
                        metadata: resources,
                        quantity: try mine.base.quantities(keys: symbols.resources)
                    ),
                    miner: try symbols.pops[mine.miner],
                    decay: mine.decay,
                    scale: mine.scale,
                    spawn: try mine.spawn.map(keys: symbols.geology),
                )
            },
            technologies: try table.technologies.mapValues {
                try .init(
                    name: $0.name,
                    starter: $1.starter,
                    effects: try $1.effects.resolved(with: symbols),
                    summary: $1.summary
                )
            },
            geology: try table.geology.reduce(into: [:]) {
                let (type, (symbol, province)): (
                    GeologicalType, (Symbol, GeologicalDescription)
                ) = $1

                $0[type] = .init(
                    id: type,
                    symbol: symbol,
                    name: province.name,
                    base: try province.base.map(keys: symbols.resources),
                    bonus: try province.bonus.map(keys: symbols.resources) {
                        .init(
                            weightNone: $0.weightNone,
                            weights: try $0.weights.map(keys: symbols.resources)
                        )
                    },
                    color: province.color
                )
            },
            terrains: table.terrains.reduce(into: [:]) {
                $0[$1.key] = .init(id: $1.key, symbol: $1.value.0, color: $1.value.1.color)
            },
            pops: try PopType.allCases.reduce(into: [:]) {
                $0[$1] = try .init(type: $1, pops: pops, symbols: symbols, resources: resources)
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

        for (key, value): (Resource, ResourceMetadata) in self.resources {
            key.hash(into: &hasher)
            value.hash.hash(into: &hasher)
        }
        for (key, value): (FactoryType, FactoryMetadata) in self.factories {
            key.hash(into: &hasher)
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
