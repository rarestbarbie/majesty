import Vector

@frozen public struct HexagonPath {
    public let d: String
}
extension HexagonPath {
    public init(c: Vector2, φ: Int8, z: Int8, size: Double = 1, tilt: HexRotation? = nil) {
        let coordinate: AxialCoordinate = .init(φ: φ, z: z)
        let c: Vector2 = c + size * Self[coordinate.q, coordinate.r, tilt: tilt]
        var d: String = "M"

        for i: Int8 in φ - 5 ..< φ - 1 {
            let i: Int8 = i < 0 ? i + 6 : i
            let v: Vector2 = c + size * Self[i, tilt: tilt]
            d += " \(v)"
        }

        d += " Z"
        self.init(d: d)
    }
    public init(c: Vector2, q: Int8, r: Int8, size: Double = 1, tilt: HexRotation? = nil) {
        let c: Vector2 = c + size * Self[q, r, tilt: tilt]

        var d: String = "M"
        for i: Int8 in 0 ..< 6 {
            let v: Vector2 = c + size * Self[i, tilt: tilt]
            d += " \(v)"
        }
        d += " Z"
        self.init(d: d)
    }
}
extension HexagonPath {
    private static var sqrt3: Double {
        1.7320508075688772
    }

    private static subscript(q: Int8, r: Int8, tilt tilt: HexRotation?) -> Vector2 {
        let x: Double
        let y: Double

        let q: Double = .init(q)
        let r: Double = .init(r)

        switch tilt {
        case nil:
            x = 1.5 * q
            y = self.sqrt3 * 0.5 * q + self.sqrt3 * r

        case .ccw?:
            x = self.sqrt3 * q + self.sqrt3 * 0.5 * r
            y = 1.5 * r

        case .cw?:
            x = self.sqrt3 * 0.5 * q - self.sqrt3 * 0.5 * r
            y = 1.5 * q + 1.5 * r
        }

        return .init(x, y)
    }
    private static subscript(i: Int8, tilt tilt: HexRotation?) -> Vector2 {
        let angle: Double = .pi / 3.0 * Double.init(i)
        return .init(radians: tilt.map { $0.angle + angle } ?? angle)
    }
}
