import HexGrids

@Identifier(Int32.self) @frozen public struct PlanetID: GameID {}

extension PlanetID {
    @inlinable public static func / (self: Self, tile: HexCoordinate) -> Address {
        .init(planet: self, tile: tile)
    }
}
