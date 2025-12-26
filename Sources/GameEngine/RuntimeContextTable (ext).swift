import GameIDs
import GameState

extension RuntimeContextTable<PlanetContext> {
    subscript(address: Address) -> PlanetGrid.Tile? {
        _read { yield self[address.planet]?.context.grid.tiles[address.tile] }
        _modify {
            if  let object: Object<PlanetContext> = self[address.planet] {
                yield &object.context.grid.tiles[address.tile]
            } else {
                var discard: PlanetGrid.Tile? = nil
                yield &discard
            }
        }
    }
}
