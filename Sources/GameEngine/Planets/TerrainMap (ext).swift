import GameIDs
import GameRules
import GameTerrain
import HexGrids

extension TerrainMap {
    func load(
        resolving symbols: GameSaveSymbols,
        geologyDefault: GeologicalType,
        ecologyDefault: EcologicalType,
    ) throws -> [Tile] {
        let defined: (
            tiles: [Address: Terrain],
            sizes: [PlanetID: Int8]
        ) = self.planetSurfaces.reduce(into: ([:], [:])) {
            for tile in $1.grid {
                $0.tiles[$1.id / tile.id] = tile
            }
            $0.sizes[$1.id] = $1.size
        }

        var tiles: [Tile] = []
        for planet: Planet in self.planets {
            let template: HexGrid = .init(radius: defined.sizes[planet.id] ?? 0)
            try template.reduce(into: ()) {
                let id: Address = planet.id / $1
                let geology: GeologicalType
                let ecology: EcologicalType
                let name: String?

                if  let tile: Terrain = defined.tiles[planet.id / $1] {
                    geology = try symbols[geology: tile.geology]
                    ecology = try symbols[ecology: tile.ecology]
                    name = tile.name
                } else {
                    geology = geologyDefault
                    ecology = ecologyDefault
                    name = nil
                }

                let tile: Tile = .init(
                    id: id,
                    type: .init(
                        ecology: ecology,
                        geology: geology
                    ),
                    name: name
                )
                tiles.append(tile)
            }
        }
        return tiles
    }
}
