import Vector

@frozen public struct HexagonPath {
    public let d: String
}
extension HexagonPath {
    public init(c: Vector2, q: Int, r: Int, size: Double) {
        // Convert axial coordinates to pixel coordinates for pointy-topped hexes
        let sqrt3: Double = 1.7320508075688772
        let center: Vector2 = c + .init(
            size * 1.5 * Double.init(q),
            size * (sqrt3 / 2.0 * Double.init(q) + sqrt3 * Double.init(r)),
        )

        // Generate SVG path data
        var d: String = "M"
        for i: Int in 0 ..< 6 {
            let corner: Vector2 = .init(
                radians: .pi / 3.0 * Double(i),
                radius: size
            )
            d += " \(center + corner)"
        }
        d += " Z"

        self.init(d: d)
    }
}
