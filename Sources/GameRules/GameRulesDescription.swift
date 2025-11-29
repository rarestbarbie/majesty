import GameEconomy
import JavaScriptInterop

public struct GameRulesDescription {
    let buildings: SymbolTable<BuildingDescription>
    let buildingCosts: BuildingCosts
    let factories: SymbolTable<FactoryDescription>
    let factoryCosts: FactoryCosts
    let resources: SymbolTable<ResourceDescription>
    let mines: SymbolTable<MineDescription>
    let pops: SymbolTable<PopDescription>
    let technologies: SymbolTable<TechnologyDescription>
    let biology: SymbolTable<CultureDescription>
    let geology: SymbolTable<GeologicalDescription>
    let terrains: SymbolTable<TerrainDescription>
    let exchange: WorldMarkets.Settings
}
extension GameRulesDescription: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<GameRules.Namespace>) throws {
        self.init(
            buildings: try js[.buildings].decode(),
            buildingCosts: try js[.building_costs].decode(),
            factories: try js[.factories].decode(),
            factoryCosts: try js[.factory_costs].decode(),
            resources: try js[.resources].decode(),
            mines: try js[.mines].decode(),
            pops: try js[.pops].decode(),
            technologies: try js[.technologies].decode(),
            biology: try js[.biology].decode(),
            geology: try js[.geology].decode(),
            terrains: try js[.terrains].decode(),
            exchange: try js[.exchange].decode(),
        )
    }
}
