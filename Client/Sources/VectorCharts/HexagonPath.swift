import Vector

@frozen public struct HexagonPath {
    public let d: String
}
extension HexagonPath {
    public init(c: Vector2, φ: Int8, z: Int8, size: Double) {
        let q: Int8
        let r: Int8

        switch φ {
        case 0: (q, r) = ( z, -z)
        case 1: (q, r) = ( 0, -z)
        case 2: (q, r) = (-z,  0)
        case 3: (q, r) = (-z,  z)
        case 4: (q, r) = ( 0,  z)
        case _: (q, r) = ( z,  0)
        }

        let center: Vector2 = c + Self[q, r, size: size]
        var d: String = "M"

        for i: Int8 in φ - 4 ..< φ {
            let i: Int8 = i < 0 ? i + 6 : i
            let v: Vector2 = center + Self[i, size: size]
            d += " \(v)"
        }

        d += " Z"
        self.init(d: d)
    }
    public init(c: Vector2, q: Int8, r: Int8, size: Double) {
        let center: Vector2 = c + Self[q, r, size: size]

        var d: String = "M"
        for i: Int8 in 0 ..< 6 {
            let v: Vector2 = center + Self[i, size: size]
            d += " \(v)"
        }
        d += " Z"
        self.init(d: d)
    }
}
extension HexagonPath {
    private static subscript(q: Int8, r: Int8, size radius: Double) -> Vector2 {
        // Convert axial coordinates to pixel coordinates
        let sqrt3: Double = 1.7320508075688772
        return .init(
            radius * 1.5 * Double.init(q),
            radius * (sqrt3 / 2.0 * Double.init(q) + sqrt3 * Double.init(r)),
        )
    }
    private static subscript(i: Int8, size radius: Double) -> Vector2 {
        let angle: Double = .pi / 3.0 * Double.init(i)
        return .init(radians: angle, radius: radius)
    }
}
