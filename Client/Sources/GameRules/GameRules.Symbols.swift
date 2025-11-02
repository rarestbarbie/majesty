import GameIDs
import JavaScriptInterop

extension GameRules {
    @frozen public struct Symbols {
        /// Pop types are not moddable.
        let pops: SymbolTable<PopType>

        var mines: SymbolTable<MineType>
        var factories: SymbolTable<FactoryType>
        var resources: SymbolTable<Resource>
        var technologies: SymbolTable<Technology>

        @usableFromInline var geology: SymbolTable<GeologicalType>
        @usableFromInline var terrains: SymbolTable<TerrainType>
    }
}
extension GameRules.Symbols {
    @inlinable public subscript(geology symbol: Symbol) -> GeologicalType {
        get throws {
            return try self.geology[symbol]
        }
    }

    @inlinable public subscript(terrain symbol: Symbol) -> TerrainType {
        get throws {
            return try self.terrains[symbol]
        }
    }
}
extension GameRules.Symbols: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<GameRules.Namespace>) {
        js[.mines] = self.mines
        js[.factories] = self.factories
        js[.resources] = self.resources
        js[.technologies] = self.technologies
        js[.geology] = self.geology
        js[.terrains] = self.terrains
    }
}
extension GameRules.Symbols: JavaScriptDecodable {
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
            geology: try js[.geology]?.decode() ?? [:],
            terrains: try js[.terrains]?.decode() ?? [:],
        )
    }
}
