@frozen public struct HexGrid {
    public let radius: Int8

    @inlinable public init(radius: Int8) {
        self.radius = radius
    }
}
extension HexGrid {
    @inlinable public func reduce<T>(
        into result: consuming T,
        with yield: (inout T, HexCoordinate) throws -> ()
    ) rethrows -> T {
        if  self.radius == 0 {
            try yield(&result, .x)
            return result
        }
        for q: Int8 in -self.radius ... self.radius {
            let r: (Int8, Int8) = (
                max(-self.radius, -q - self.radius),
                min( self.radius, -q + self.radius)
            )
            for r: Int8 in r.0 ... r.1 {
                let coordinate: AxialCoordinate = .init(q: q, r: r)
                if  self.radius > 2,
                    let φ: Int8 = coordinate.φ(self.radius) {
                    try yield(&result, .e(φ))
                } else {
                    try yield(&result, .n(q, r))
                    try yield(&result, .s(q, r))
                }
            }
        }
        return result
    }
}
