import GameIDs
import GameRules
import GameState

extension RuntimeContextTable<TileContext> {
    mutating func replace(planet: PlanetID, with moved: [Tile], metadata: inout GameMetadata) throws {
        self.prune { $0.planet != planet }
        for moved: Tile in moved {
            try self.append(moved) { metadata.tiles[$0.type] }
        }
    }
}
