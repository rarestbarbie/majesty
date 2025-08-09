import GameEconomy
import JavaScriptInterop

public struct GameRulesDescription {
    let factories: SymbolTable<FactoryDescription>
    let factory_costs: SymbolTable<SymbolTable<Int64>>
    let resources: SymbolTable<ResourceDescription>
    let pops: SymbolTable<PopDescription>
    let technologies: SymbolTable<TechnologyDescription>
    let terrains: SymbolTable<TerrainDescription>
}
extension GameRulesDescription: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<GameRules.Namespace>) throws {
        self.init(
            factories: try js[.factories].decode(),
            factory_costs: try js[.factory_costs].decode(),
            resources: try js[.resources].decode(),
            pops: try js[.pops].decode(),
            technologies: try js[.technologies].decode(),
            terrains: try js[.terrains].decode(),
        )
    }
}
