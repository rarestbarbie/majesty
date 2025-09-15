import Color
import GameEconomy
import OrderedCollections

@frozen public struct GameRules {
    public let resources: OrderedDictionary<Resource, ResourceMetadata>
    public let factories: OrderedDictionary<FactoryType, FactoryMetadata>
    public let technologies: OrderedDictionary<Technology, TechnologyMetadata>
    public let geology: OrderedDictionary<GeologicalType, GeologicalMetadata>
    public let terrains: OrderedDictionary<TerrainType, TerrainMetadata>

    public let pops: [PopType: PopMetadata]

    public let settings: Settings

    @inlinable public init(
        resources: OrderedDictionary<Resource, ResourceMetadata>,
        factories: OrderedDictionary<FactoryType, FactoryMetadata>,
        technologies: OrderedDictionary<Technology, TechnologyMetadata>,
        geology: OrderedDictionary<GeologicalType, GeologicalMetadata>,
        terrains: OrderedDictionary<TerrainType, TerrainMetadata>,
        pops: [PopType: PopMetadata],
        settings: Settings
    ) {
        self.resources = resources
        self.factories = factories
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
        technologies: OrderedDictionary<Technology, (Symbol, TechnologyDescription)>,
        geology: OrderedDictionary<GeologicalType, (Symbol, GeologicalDescription)>,
        terrains: OrderedDictionary<TerrainType, (Symbol, TerrainDescription)>
    )
}
extension GameRules {
    public init(
        resolving rules: borrowing GameRulesDescription,
        with symbols: inout GameRules.Symbols
    ) throws {
        try self.init(
            resolving: rules,
            table: (
                try symbols.resources.extend(over: rules.resources),
                try symbols.factories.extend(over: rules.factories),
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
        symbols: GameRules.Symbols,
        settings: Settings
    ) throws {
        let pops: EffectsTable<PopType, PopDescription> = try symbols.pops.resolve(rules.pops)
        let resources: OrderedDictionary<Resource, ResourceMetadata> = table.resources.mapValues {
            .init(name: $0.name, color: $1.color, emoji: $1.emoji, local: $1.local)
        }

        let factoryCosts: EffectsTable<FactoryType, SymbolTable<Int64>> = try symbols.factories.resolve(
            rules.factory_costs
        )
        self.init(
            resources: resources,
            factories: try table.factories.reduce(
                into: [:]
            ) {
                let (type, (symbol, factory)): (FactoryType, (Symbol, FactoryDescription)) = $1
                $0[type] = try .init(
                    name: symbol.name,
                    costs: .init(
                        metadata: resources,
                        quantity: try symbols.resources.resolve(
                            try factoryCosts[type] ?? factoryCosts[*]
                        )
                    ),
                    inputs: .init(
                        metadata: resources,
                        quantity: try symbols.resources.resolve(factory.inputs)
                    ),
                    output: .init(
                        metadata: resources,
                        quantity: try symbols.resources.resolve(factory.output)
                    ),
                    workers: try symbols.pops.resolve(factory.workers)
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
            geology: try table.geology.reduce(
                into: [:]
            ) {
                let (type, (symbol, province)): (
                    GeologicalType, (Symbol, GeologicalDescription)
                ) = $1

                $0[type] = .init(
                    id: type,
                    symbol: symbol,
                    name: province.name,
                    base: try symbols.resources.resolve(province.base),
                    bonus: try symbols.resources.resolve(province.bonus) {
                        .init(
                            weightNone: $0.weightNone,
                            weights: try symbols.resources.resolve($0.weights)
                        )
                    },
                    color: province.color
                )
            },
            terrains: table.terrains.reduce(into: [:]) {
                $0[$1.key] = .init(id: $1.key, symbol: $1.value.0, color: $1.value.1.color)
            },
            pops: try PopType.allCases.reduce(into: [:]) {
                let pop: PopDescription? = pops[$1]
                let l: SymbolTable<Int64> = try pop?.l ?? pops[*].l ?? [:]
                let e: SymbolTable<Int64> = try pop?.e ?? pops[*].e ?? [:]
                let x: SymbolTable<Int64> = try pop?.x ?? pops[*].x ?? [:]
                let output: SymbolTable<Int64> = try pop?.output ?? pops[*].output ?? [:]
                $0[$1] = .init(
                    singular: $1.singular,
                    plural: $1.plural,
                    color: try pop?.color ?? pops[*].color ?? 0xFFFFFF,
                    l: .init(metadata: resources, quantity: try symbols.resources.resolve(l)),
                    e: .init(metadata: resources, quantity: try symbols.resources.resolve(e)),
                    x: .init(metadata: resources, quantity: try symbols.resources.resolve(x)),
                    output: .init(
                        metadata: resources,
                        quantity: try symbols.resources.resolve(output)
                    )
                )
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
