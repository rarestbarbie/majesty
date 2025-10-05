import GameState

extension RuntimeContextTable<PlanetContext> {
    subscript(address: Address) -> PlanetGrid.Tile? {
        _read { yield self[address.planet]?.grid.tiles[address.tile] }
        _modify {
            if  let i: Int = self.find(id: address.planet) {
                yield &self[i].grid.tiles[address.tile]
            } else {
                var discard: PlanetGrid.Tile? = nil
                yield &discard
            }
        }
    }
}
