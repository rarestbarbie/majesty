import Color
import GameEconomy
import GameIDs
import OrderedCollections

@frozen public struct GameRules {
    public let resources: Resources
    public let buildings: OrderedDictionary<BuildingType, BuildingMetadata>
    public let factories: OrderedDictionary<FactoryType, FactoryMetadata>
    public let mines: OrderedDictionary<MineType, MineMetadata>
    public let technologies: OrderedDictionary<Technology, TechnologyMetadata>
    public let biology: OrderedDictionary<CultureType, CultureMetadata>
    public let geology: OrderedDictionary<GeologicalType, GeologicalMetadata>
    public let terrains: OrderedDictionary<TerrainType, TerrainMetadata>

    public let pops: [PopType: PopMetadata]

    public let settings: Settings
}
extension GameRules {
    private typealias Tables = (
        resources: OrderedDictionary<SymbolAssignment<Resource>, ResourceDescription>,
        buildings: OrderedDictionary<SymbolAssignment<BuildingType>, BuildingDescription>,
        factories: OrderedDictionary<SymbolAssignment<FactoryType>, FactoryDescription>,
        mines: OrderedDictionary<SymbolAssignment<MineType>, MineDescription>,
        technologies: OrderedDictionary<SymbolAssignment<Technology>, TechnologyDescription>,
        biology: OrderedDictionary<SymbolAssignment<CultureType>, CultureDescription>,
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
                try symbols.buildings.extend(over: rules.buildings),
                try symbols.factories.extend(over: rules.factories),
                try symbols.mines.extend(over: rules.mines),
                try symbols.technologies.extend(over: rules.technologies),
                try symbols.biology.extend(over: rules.biology),
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
                critical: $1.critical ?? false,
                storable: $1.storable ?? false,
                hours: $1.hours
            )
        }

        let maintenanceCosts: EffectsTable<
            BuildingType,
            SymbolTable<Int64>
        > = try rules.buildingCosts.maintenance.effects(keys: symbols.buildings, wildcard: "*")
        let developmentCosts: EffectsTable<
            BuildingType,
            SymbolTable<Int64>
        > = try rules.buildingCosts.development.effects(keys: symbols.buildings, wildcard: "*")

        let corporateCosts: EffectsTable<
            FactoryType,
            SymbolTable<Int64>
        > = try rules.factoryCosts.corporate.effects(keys: symbols.factories, wildcard: "*")
        let expansionCosts: EffectsTable<
            FactoryType,
            SymbolTable<Int64>
        > = try rules.factoryCosts.expansion.effects(keys: symbols.factories, wildcard: "*")

        self.init(
            resources: resources,
            buildings: try table.buildings.map {
                BuildingMetadata.init(
                    identity: $0,
                    maintenance: .init(
                        metadata: resources,
                        quantity: try (
                            try maintenanceCosts[$0.code] ?? maintenanceCosts[*]
                        ).quantities(
                            keys: symbols.resources
                        )
                    ),
                    development: .init(
                        metadata: resources,
                        quantity: try (
                            try developmentCosts[$0.code] ?? developmentCosts[*]
                        ).quantities(
                            keys: symbols.resources
                        )
                    ),
                    output: .init(
                        metadata: resources,
                        quantity: try $1.output.quantities(keys: symbols.resources)
                    ),
                    sharesInitial: rules.buildingCosts.sharesInitial,
                    sharesPerLevel: rules.buildingCosts.sharesPerLevel,
                    terrainAllowed: .init(
                        try $1.terrain.lazy.map { try symbols.terrains[$0] }
                    ),
                    required: $1.required
                )
            },
            factories: try table.factories.map {
                try FactoryMetadata.init(
                    identity: $0,
                    materials: .init(
                        metadata: resources,
                        quantity: try $1.materials.quantities(keys: symbols.resources)
                    ),
                    corporate: .init(
                        metadata: resources,
                        quantity: try (
                            try $1.corporate ?? corporateCosts[$0.code] ?? corporateCosts[*]
                        ).quantities(
                            keys: symbols.resources
                        )
                    ),
                    expansion: .init(
                        metadata: resources,
                        quantity: try (
                            try $1.expansion ?? expansionCosts[$0.code] ?? expansionCosts[*]
                        ).quantities(
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
                MineMetadata.init(
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
                TechnologyMetadata.init(
                    identity: $0 as SymbolAssignment<Technology>,
                    starter: $1.starter,
                    effects: try $1.effects.resolved(with: symbols),
                    summary: $1.summary
                )
            },
            biology: try table.biology.map {
                CultureMetadata.init(
                    identity: $0,
                    diet: .init(
                        metadata: resources,
                        quantity: try $1.diet.quantities(keys: symbols.resources)
                    ),
                    meat: .init(
                        metadata: resources,
                        quantity: try $1.meat.quantities(keys: symbols.resources)
                    )
                )
            },
            geology: try table.geology.map {
                GeologicalMetadata.init(
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
                TerrainMetadata.init(identity: $0, color: $1.color)
            },
            pops: try PopType.allCases.map(to: [PopType: PopMetadata].self) {
                try PopMetadata.init(
                    id: $0,
                    effects: pops,
                    symbols: symbols,
                    resources: resources
                )
            },
            settings: settings
        )
    }

    private init(
        resources: OrderedDictionary<Resource, ResourceMetadata>,
        buildings: OrderedDictionary<BuildingType, BuildingMetadata>,
        factories: OrderedDictionary<FactoryType, FactoryMetadata>,
        mines: OrderedDictionary<MineType, MineMetadata>,
        technologies: OrderedDictionary<Technology, TechnologyMetadata>,
        biology: OrderedDictionary<CultureType, CultureMetadata>,
        geology: OrderedDictionary<GeologicalType, GeologicalMetadata>,
        terrains: OrderedDictionary<TerrainType, TerrainMetadata>,
        pops: [PopType: PopMetadata],
        settings: Settings
    ) {
        self.init(
            resources: .init(
                fallback: .init(
                    identity: .init(code: .init(rawValue: -1), symbol: "_Unknown"),
                    color: 0xFFFFFF,
                    emoji: "?",
                    local: false,
                    critical: false,
                    storable: false,
                    hours: nil
                ),
                local: resources.values.filter(\.local),
                table: resources
            ),
            buildings: buildings,
            factories: factories,
            mines: mines,
            technologies: technologies,
            biology: biology,
            geology: geology,
            terrains: terrains,
            pops: pops,
            settings: settings,
        )
    }
}
extension GameRules {
    /// Compute a slow hash of the game rules, used for checking mod compatibility.
    public var hash: Int {
        var hasher: Hasher = .init()

        // TODO: hash settings

        for value: ResourceMetadata in self.resources.all {
            value.hash.hash(into: &hasher)
        }
        for value: FactoryMetadata in self.factories.values {
            value.hash.hash(into: &hasher)
        }
        for value: MineMetadata in self.mines.values {
            value.hash.hash(into: &hasher)
        }
        for value: TechnologyMetadata in self.technologies.values {
            value.hash.hash(into: &hasher)
        }
        for value: GeologicalMetadata in self.geology.values {
            value.hash.hash(into: &hasher)
        }
        for value: TerrainMetadata in self.terrains.values {
            value.hash.hash(into: &hasher)
        }
        for value: PopMetadata in self.pops.values.sorted(by: { $0.id < $1.id }) {
            value.hash.hash(into: &hasher)
        }

        return hasher.finalize()
    }
}
