import Vector

extension Vector2 {
    @frozen @usableFromInline struct ArcGeometry: Sendable {
        @usableFromInline let share: Double
        @usableFromInline let startArc: Vector2
        @usableFromInline let endArc: Vector2
        /// The end of the slice, in radians.
        @usableFromInline let end: Double

        @inlinable init(share: Double, startArc: Vector2, endArc: Vector2, end: Double) {
            self.share = share
            self.startArc = startArc
            self.endArc = endArc
            self.end = end
        }
    }
}
extension Vector2.ArcGeometry {
    @inlinable init(share: Double, from start: Vector2, to end: Double) {
        self.init(
            share: share,
            startArc: start,
            endArc: .init(radians: end),
            end: end
        )
    }
}
extension Vector2.ArcGeometry {
    @usableFromInline var d: String {
        var d: String = "M 0,0 L \(self.startArc)"
        switch self.share {
        case 0 ..< 0.375:
            d += " A 1,1 0 0 0 \(self.endArc)"

        case 0.625 ... 1:
            d += " A 1,1 0 1 0 \(self.endArc)"

        case _:
            //  Near-semicircular arc; split into 2 segments to avoid degenerate behavior.
            let p: Vector2 = .init(radians: self.end - 0.5 * Double.pi)
            d += " A 1,1 0 0 0 \(p) A 1,1 0 0 0 \(self.endArc)"
        }

        if  self.endArc.x >= 0,
            self.endArc.y == 0 {
            d += " Z"
        } else if
            self.endArc.x >= 0,
            self.endArc.y >= 0 {
            var fringe: Vector2 = .init(radians: self.end + 0.1) * 0.5
            fringe.y = max(fringe.y, 0)

            d += " L \(fringe) Z"
        } else {
            let fringe: Vector2 = .init(radians: self.end + 0.1) * 0.5
            d += " L \(fringe) Z"
        }

        return d
    }
}
