import Color
import GameIDs
import GameRules
import GameTerrain
import HexGrids
import OrderedCollections
import Vector

struct PlanetGrid {
    var tiles: OrderedDictionary<HexCoordinate, Tile>
    var size: Int8

    init(
        tiles: OrderedDictionary<HexCoordinate, Tile> = [:],
        size: Int8 = 0
    ) {
        self.tiles = tiles
        self.size = size
    }
}
extension PlanetGrid {
    mutating func replace(
        surface: PlanetSurface,
        symbols: GameSaveSymbols,
        rules: GameMetadata,
        terrainDefault: TerrainMetadata,
        geologyDefault: GeologicalMetadata
    ) throws {
        self.tiles = try Self.resolve(
            surface: surface,
            symbols: symbols,
            rules: rules,
        )
        self.reshape(
            planet: surface.id,
            size: surface.size,
            terrainDefault: terrainDefault,
            geologyDefault: geologyDefault
        )
    }

    mutating func resurface(
        planet: PlanetID,
        rotate: HexRotation?,
        size: Int8,
        terrainDefault: TerrainMetadata,
        geologyDefault: GeologicalMetadata
    ) {
        if  self.size != size {
            self.reshape(
                planet: planet,
                size: size,
                terrainDefault: terrainDefault,
                geologyDefault: geologyDefault
            )
        }
        if  let rotate: HexRotation {
            /// OrderedDictionary is a value type, which does the Right Thing here, as we do
            /// not want to copy data from newly updated tiles.
            for source: Tile in self.tiles.values {
                let id: HexCoordinate
                switch rotate {
                case .ccw:
                    switch source.id.tile {
                    case .x:                id = .x
                    case .n(let q, let r):  id = .n(r + q, -q)
                    case .e(let φ):         id = .e(φ == 5 ? 0 : φ + 1)
                    case .s(let q, let r):  id = .s(r + q, -q)
                    }

                case .cw:
                    switch source.id.tile {
                    case .x:                id = .x
                    case .n(let q, let r):  id = .n(-r, r + q)
                    case .e(let φ):         id = .e(φ == 0 ? 5 : φ - 1)
                    case .s(let q, let r):  id = .s(-r, r + q)
                    }
                }

                self.tiles[id]?.copy(from: source)
            }
        }
    }
}
extension PlanetGrid {
    private mutating func reshape(
        planet: PlanetID,
        size: Int8,
        terrainDefault: TerrainMetadata,
        geologyDefault: GeologicalMetadata
    ) {
        let template: HexGrid = .init(radius: size)

        self.size = size
        self.tiles = template.reduce(into: [:]) {
            $0[$1] = self.tiles[$1] ?? Tile.init(
                id: planet / $1,
                name: nil,
                terrain: terrainDefault,
                geology: geologyDefault
            )
        }
    }

    private static func resolve(
        surface: PlanetSurface?,
        symbols: GameSaveSymbols,
        rules: GameMetadata
    ) throws -> OrderedDictionary<HexCoordinate, Tile> {
        var tiles: OrderedDictionary<HexCoordinate, Tile> = [:]

        guard let surface: PlanetSurface else {
            return tiles
        }

        tiles.reserveCapacity(surface.grid.count)

        for tile: PlanetSurface.Tile in surface.grid {
            guard
            let terrain: TerrainMetadata = rules.terrains[
                try symbols[terrain: tile.terrain]
            ] else {
                fatalError("Missing terrain metadata for \(tile.terrain)!!!")
            }
            guard
            let geology: GeologicalMetadata = rules.geology[
                try symbols[geology: tile.geology]
            ] else {
                fatalError("Missing geological metadata for \(tile.geology)!!!")
            }

            tiles[tile.id] = Tile.init(
                id: surface.id / tile.id,
                name: tile.name,
                terrain: terrain,
                geology: geology
            )
        }

        return tiles
    }
}
