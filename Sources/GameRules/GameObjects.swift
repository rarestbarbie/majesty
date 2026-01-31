import Color
import GameEconomy
import GameIDs
import OrderedCollections

struct GameObjects {
    let resources: OrderedDictionary<Resource, ResourceMetadata>
    let buildings: OrderedDictionary<BuildingType, BuildingMetadata>
    let factories: OrderedDictionary<FactoryType, FactoryMetadata>
    let mines: OrderedDictionary<MineType, MineMetadata>
    let technologies: OrderedDictionary<Technology, TechnologyMetadata>
}
extension GameObjects {
    /// It is critical here that `symbols` is the last parameter, because Swift evaluates
    /// function arguments from left to right.
    init(
        resolving rules: borrowing GameRules,
        table: (
            resources: OrderedDictionary<SymbolAssignment<Resource>, ResourceDescription>,
            buildings: OrderedDictionary<SymbolAssignment<BuildingType>, BuildingDescription>,
            factories: OrderedDictionary<SymbolAssignment<FactoryType>, FactoryDescription>,
            mines: OrderedDictionary<SymbolAssignment<MineType>, MineDescription>,
            technologies: OrderedDictionary<SymbolAssignment<Technology>, TechnologyDescription>,
        ),
        symbols: GameSaveSymbols,
    ) throws {
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
                    color: $1.color,
                    operations: try .init(
                        metadata: resources,
                        quantity: $1.operations,
                        symbols: symbols.resources
                    ),
                    maintenance: try .init(
                        metadata: resources,
                        quantity: $1.maintenance
                            ?? maintenanceCosts[$0.code]
                            ?? maintenanceCosts[*],
                        symbols: symbols.resources
                    ),
                    development: try .init(
                        metadata: resources,
                        quantity: $1.development
                            ?? developmentCosts[$0.code]
                            ?? developmentCosts[*],
                        symbols: symbols.resources
                    ),
                    output: try .init(
                        metadata: resources,
                        quantity: $1.output,
                        symbols: symbols.resources
                    ),
                    sharesInitial: rules.buildingCosts.sharesInitial,
                    sharesPerLevel: rules.buildingCosts.sharesPerLevel,
                    terrainAllowed: .init(
                        try $1.terrain.lazy.map { try symbols.ecology[$0] }
                    ),
                    required: $1.required
                )
            },
            factories: try table.factories.map {
                try FactoryMetadata.init(
                    identity: $0,
                    color: $1.color,
                    materials: try .init(
                        metadata: resources,
                        quantity: $1.materials,
                        symbols: symbols.resources
                    ),
                    corporate: try .init(
                        metadata: resources,
                        quantity: $1.corporate ?? corporateCosts[$0.code] ?? corporateCosts[*],
                        symbols: symbols.resources
                    ),
                    expansion: try .init(
                        metadata: resources,
                        quantity: $1.expansion ?? expansionCosts[$0.code] ?? expansionCosts[*],
                        symbols: symbols.resources
                    ),
                    output: try .init(
                        metadata: resources,
                        quantity: $1.output,
                        symbols: symbols.resources
                    ),
                    workers: try $1.workers.quantities(keys: symbols.occupations),
                    sharesInitial: rules.factoryCosts.sharesInitial,
                    sharesPerLevel: rules.factoryCosts.sharesPerLevel,
                    terrainAllowed: .init(
                        try $1.terrain.lazy.map { try symbols.ecology[$0] }
                    )
                )
            },
            mines: try table.mines.map {
                MineMetadata.init(
                    identity: $0,
                    base: try .init(
                        metadata: resources,
                        quantity: $1.base,
                        symbols: symbols.resources
                    ),
                    miner: try symbols.occupations[$1.miner],
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
        )
    }
}
