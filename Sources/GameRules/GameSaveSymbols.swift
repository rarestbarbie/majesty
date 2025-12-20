import GameIDs
import JavaScriptInterop

@frozen public struct GameSaveSymbols: Sendable {
    /// Pop types are not moddable.
    public let occupations: SymbolTable<PopOccupation>
    public let genders: SymbolTable<Gender>

    public internal(set) var mines: SymbolTable<MineType>
    public internal(set) var buildings: SymbolTable<BuildingType>
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
    public func encode(to js: inout JavaScriptEncoder<GameMetadata.Namespace>) {
        js[.mines] = self.mines
        js[.buildings] = self.buildings
        js[.factories] = self.factories
        js[.resources] = self.resources
        js[.technologies] = self.technologies
        js[.biology] = self.biology
        js[.geology] = self.geology
        js[.terrains] = self.terrains
    }
}
extension GameSaveSymbols: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<GameMetadata.Namespace>) throws {
        self.init(
            occupations: .init(
                index: PopOccupation.allCases.reduce(into: [:]) {
                    $0[.init(name: $1.singular)] = $1
                }
            ),
            genders: .init(index: Gender.allCases.reduce(into: [:]) { $0[$1.code] = $1 }),
            mines: try js[.mines]?.decode() ?? [:],
            buildings: try js[.buildings]?.decode() ?? [:],
            factories: try js[.factories]?.decode() ?? [:],
            resources: try js[.resources]?.decode() ?? [:],
            technologies: try js[.technologies]?.decode() ?? [:],
            biology: try js[.biology]?.decode() ?? [:],
            geology: try js[.geology]?.decode() ?? [:],
            terrains: try js[.terrains]?.decode() ?? [:],
        )
    }
}
