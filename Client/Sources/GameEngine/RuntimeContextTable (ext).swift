import GameState

extension RuntimeContextTable<PlanetContext> {
    subscript(address: Address) -> PlanetGrid.Tile? {
        self[address.planet]?.grid.tiles[address.tile]
    }
}
