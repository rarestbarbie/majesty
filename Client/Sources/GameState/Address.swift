import GameEngine
import HexGrids
import JavaScriptKit
import JavaScriptInterop

@frozen public struct Address: Equatable, Hashable, Sendable {
    public let planet: GameID<Planet>
    public let tile: HexCoordinate

    @inlinable public init(planet: GameID<Planet>, tile: HexCoordinate) {
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
        let planet: GameID<Planet> = .init(string[..<prefix]),
        let tile: HexCoordinate = .init(string[prefix...]) else {
            return nil
        }

        self.init(planet: planet, tile: tile)
    }
}
extension Address: LoadableFromJSString, ConvertibleToJSString {
}
