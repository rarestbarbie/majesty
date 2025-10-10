import HexGrids

@frozen public struct Address: Equatable, Hashable, Sendable {
    public let planet: PlanetID
    public let tile: HexCoordinate

    @inlinable public init(planet: PlanetID, tile: HexCoordinate) {
        self.planet = planet
        self.tile = tile
    }
}
extension Address: CustomStringConvertible {
    @inlinable public var description: String {
        "\(self.planet)\(self.tile)"
    }
}
extension Address: LosslessStringConvertible {
    @inlinable public init?(_ string: some StringProtocol) {
        guard
        let prefix: String.Index = string.firstIndex(where: { !$0.isNumber }),
        let planet: PlanetID = .init(string[..<prefix]),
        let tile: HexCoordinate = .init(string[prefix...]) else {
            return nil
        }

        self.init(planet: planet, tile: tile)
    }
}
