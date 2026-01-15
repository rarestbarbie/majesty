import GameEconomy
import GameIDs
import JavaScriptInterop
import OrderedCollections

public struct GameRules: Sendable {
    let legend: Legend.Description
    let pops: [PopAttributesDescription]

    let buildings: SymbolTable<BuildingDescription>
    let buildingCosts: BuildingCosts
    let factories: SymbolTable<FactoryDescription>
    let factoryCosts: FactoryCosts
    let resources: SymbolTable<ResourceDescription>
    let mines: SymbolTable<MineDescription>
    let technologies: SymbolTable<TechnologyDescription>
    let biology: SymbolTable<BiologicalDescription>
    let ecology: SymbolTable<EcologicalDescription>
    let geology: SymbolTable<GeologicalDescription>

    let settings: GameMetadata.Settings
}
extension GameRules {
    public func resolve(symbols: inout GameSaveSymbols) throws -> GameMetadata {
        // biology table currently only used to assign stable IDs to biological types
        _ = try symbols.biology.extend(over: self.biology)

        let objects: GameObjects = try .init(
            resolving: self,
            table: (
                try symbols.resources.extend(over: self.resources),
                try symbols.buildings.extend(over: self.buildings),
                try symbols.factories.extend(over: self.factories),
                try symbols.mines.extend(over: self.mines),
                try symbols.technologies.extend(over: self.technologies),
            ),
            symbols: symbols,
        )

        /// due to order of evaluation, we must mutate symbols here, before calling `init`
        let ecology: OrderedDictionary<
            SymbolAssignment<EcologicalType>,
            EcologicalDescription
        > = try symbols.ecology.extend(over: self.ecology)
        let geology: OrderedDictionary<
            SymbolAssignment<GeologicalType>,
            GeologicalDescription
        > = try symbols.geology.extend(over: self.geology)

        return try .init(
            symbols: symbols,
            objects: objects,
            settings: self.settings,
            legend: self.legend,
            ecology: ecology,
            geology: geology,
            pops: self.pops,
        )
    }
}
extension GameRules: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<GameMetadata.Namespace>) throws {
        self.init(
            legend: try js[.legend].decode(),
            pops: try js[.pops].decode(),
            buildings: try js[.buildings].decode(),
            buildingCosts: try js[.building_costs].decode(),
            factories: try js[.factories].decode(),
            factoryCosts: try js[.factory_costs].decode(),
            resources: try js[.resources].decode(),
            mines: try js[.mines].decode(),
            technologies: try js[.technologies].decode(),
            biology: try js[.biology].decode(),
            ecology: try js[.ecology].decode(),
            geology: try js[.geology].decode(),
            settings: try js[.settings].decode(),
        )
    }
}
