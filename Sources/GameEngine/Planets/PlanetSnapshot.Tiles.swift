import Color
import GameIDs
import HexGrids
import Vector

extension PlanetSnapshot {
    struct Tiles: Sendable {
        let planet: PlanetSnapshot
        let cached: [Address: PlanetGrid.TileSnapshot]
    }
}
extension PlanetSnapshot.Tiles {
    func color(_ color: (PlanetGrid.TileSnapshot) -> Color) -> [PlanetMapTile] {
        self.color { (color($0), nil, nil, nil) }
    }
    func color(_ color: (PlanetGrid.TileSnapshot) -> Double) -> [PlanetMapTile] {
        self.color { (nil, color($0), nil, nil) }
    }
    func color(_ color: (PlanetGrid.TileSnapshot) -> (x: Double, y: Double)) -> [PlanetMapTile] {
        self.color {
            let (x, y): (Double, Double) = color($0)
            return (nil, x, y, nil)
        }
    }
    func color(_ color: (PlanetGrid.TileSnapshot) -> (x: Double, y: Double, z: Double)) -> [PlanetMapTile] {
        self.color {
            let (x, y, z): (Double, Double, Double) = color($0)
            return (nil, x, y, z)
        }
    }

    private func color(
        _ color: (PlanetGrid.TileSnapshot) -> (color: Color?, x: Double?, y: Double?, z: Double?)
    ) -> [PlanetMapTile] {
        let z: Int8 = self.planet.grid.radius
        let radius: Double = 1.5 * Double.init(1 + z)
        let center: (north: Vector2, south: Vector2) = (
            north: .init(-radius, 0),
            south: .init(+radius, 0),
        )

        let tilt: HexRotation? = z > 2 ? .ccw : nil

        return self.reduce(into: []) {
            let shape: (HexagonPath, HexagonPath?)

            switch $1 {
            case .x:
                shape.0 = .init(c: .zero, q: 0, r: 0, tilt: tilt)
                shape.1 = nil

            case .n(let q, let r):
                shape.0 = .init(c: center.north, q: q, r: r, tilt: tilt)
                shape.1 = nil

            case .e(let φ):
                let θ: Int8 = φ > 4 ? 10 - φ : 4 - φ
                shape.0 = .init(c: center.north, φ: φ, z: z, tilt: tilt)
                shape.1 = .init(c: center.south, φ: θ, z: z, tilt: tilt?.inverted)

            case .s(let q, let r):
                /// Project the southern hemisphere as if it were viewed from the south pole.
                let (q, r): (Int8, Int8) = (-q, r + q)
                shape.0 = .init(c: center.south, q: q, r: r, tilt: tilt?.inverted)
                shape.1 = nil
            }

            let (color, x, y, z): (Color?, Double?, Double?, Double?) = color($2)

            $0.append(
                PlanetMapTile.init(
                    id: $1,
                    shape: shape,
                    color: color,
                    x: x,
                    y: y,
                    z: z
                )
            )
        }
    }

    func reduce<T>(
        initial: consuming T,
        combine: (consuming T, HexCoordinate, PlanetGrid.TileSnapshot) throws -> T
    ) rethrows -> T {
        try self.reduce(into: initial) {
            $0 = try combine($0, $1, $2)
        }
    }

    func reduce<T>(
        into result: consuming T,
        with yield: (inout T, HexCoordinate, PlanetGrid.TileSnapshot) throws -> ()
    ) rethrows -> T {
        try self.planet.grid.reduce(into: result) {
            guard
            let tile: PlanetGrid.TileSnapshot = self.cached[self.planet.state.id / $1] else {
                return
            }

            try yield(&$0, $1, tile)
        }
    }
}
