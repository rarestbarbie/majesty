import GameTerrain

extension PlanetSurface.Tile {
    init(from tile: PlanetGrid.Tile) {
        self.init(
            id: tile.id.tile,
            name: tile.name,
            terrain: tile.terrain.symbol,
            geology: tile.geology.symbol
        )
    }
}
