import GameIDs
import JavaScriptInterop

@frozen public struct GameSaveSymbols {
    /// Pop types are not moddable.
    public let pops: SymbolTable<PopType>

    public internal(set) var mines: SymbolTable<MineType>
    public internal(set) var factories: SymbolTable<FactoryType>
    public internal(set) var resources: SymbolTable<Resource>
    public internal(set) var technologies: SymbolTable<Technology>

    @usableFromInline var biology: SymbolTable<CultureType>
    @usableFromInline var geology: SymbolTable<GeologicalType>
    @usableFromInline var terrains: SymbolTable<TerrainType>
}
extension GameSaveSymbols {
    @inlinable public subscript(biology symbol: Symbol) -> CultureType {
        get throws { try self.biology[symbol] }
    }

    @inlinable public subscript(geology symbol: Symbol) -> GeologicalType {
        get throws { try self.geology[symbol] }
    }

    @inlinable public subscript(terrain symbol: Symbol) -> TerrainType {
        get throws { try self.terrains[symbol] }
    }
}
extension GameSaveSymbols: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<GameRules.Namespace>) {
        js[.mines] = self.mines
        js[.factories] = self.factories
        js[.resources] = self.resources
        js[.technologies] = self.technologies
        js[.biology] = self.biology
        js[.geology] = self.geology
        js[.terrains] = self.terrains
    }
}
extension GameSaveSymbols: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<GameRules.Namespace>) throws {
        self.init(
            pops: .init(
                index: PopType.allCases.reduce(into: [:]) {
                    $0[.init(name: $1.singular)] = $1
                }
            ),
            mines: try js[.mines]?.decode() ?? [:],
            factories: try js[.factories]?.decode() ?? [:],
            resources: try js[.resources]?.decode() ?? [:],
            technologies: try js[.technologies]?.decode() ?? [:],
            biology: try js[.biology]?.decode() ?? [:],
            geology: try js[.geology]?.decode() ?? [:],
            terrains: try js[.terrains]?.decode() ?? [:],
        )
    }
}
