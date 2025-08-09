@frozen public struct HexGrid {
    public let radius: Int8

    @inlinable public init(radius: Int8) {
        self.radius = radius
    }
}
extension HexGrid {
    @inlinable public func reduce<T>(
        into result: consuming T,
        with yield: (inout T, HexCoordinate) throws -> ()) rethrows -> T {
        for q: Int8 in -self.radius ... self.radius {
            let r: (Int8, Int8) = (
                max(-self.radius, -q - self.radius),
                min( self.radius, -q + self.radius)
            )
            for r: Int8 in r.0 ... r.1 {
                let coordinate: AxialCoordinate = .init(q: q, r: r)
                let north: HexCoordinate = .init(hemisphere: .north, coordinate: coordinate)
                let south: HexCoordinate = .init(hemisphere: .south, coordinate: coordinate)

                try yield(&result, north)
                try yield(&result, south)
            }
        }
        return result
    }
}
