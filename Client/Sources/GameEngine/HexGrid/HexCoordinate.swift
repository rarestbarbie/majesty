@frozen public struct HexCoordinate: Equatable, Hashable, Sendable {
    public let hemisphere: Hemisphere
    public let coordinate: AxialCoordinate

    @inlinable public init(hemisphere: Hemisphere, coordinate: AxialCoordinate) {
        self.hemisphere = hemisphere
        self.coordinate = coordinate
    }
}
extension HexCoordinate {
    @inlinable public var q: Int8 { self.coordinate.q }
    @inlinable public var r: Int8 { self.coordinate.r }
}
extension HexCoordinate: CustomStringConvertible {
    @inlinable public var description: String {
        switch self.hemisphere {
        case .north: "N\(self.coordinate)"
        case .south: "S\(self.coordinate)"
        }
    }
}
extension HexCoordinate: LosslessStringConvertible {
    @inlinable public init?(_ string: some StringProtocol) {
        guard
        let first: String.Index = string.indices.first else {
            return nil
        }

        let hemisphere: Hemisphere

        switch string[first] {
        case "N":   hemisphere = .north
        case "S":   hemisphere = .south
        default:    return nil
        }

        guard
        let coordinate: AxialCoordinate = .init(string[string.index(after: first)...]) else {
            return nil
        }

        self.init(hemisphere: hemisphere, coordinate: coordinate)
    }
}
