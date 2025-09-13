@frozen public enum HexCoordinate: Equatable, Hashable, Sendable {
    /// Solitary tile.
    case x
    /// Northern hemisphere tile.
    case n(_ q: Int8, _ r: Int8)
    /// Equatorial tile, appears to the player as two fragments.
    case e(_ φ: Int8)
    /// Southern hemisphere tile.
    case s(_ q: Int8, _ r: Int8)
}

extension HexCoordinate {
    static func e(_ q: Int8, _ r: Int8) -> Self {
        let a: AxialCoordinate = .init(q: q, r: r)
        guard let φ: Int8 = a.φ(1) else {
            fatalError("Axial coordinate \(a) is not an equatorial cell")
        }
        return .e(φ)
    }
}
extension HexCoordinate: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .x: "X"
        case .n(let q, let r): "N\(q),\(r)"
        case .e(let φ): "E\(φ)"
        case .s(let q, let r): "S\(q),\(r)"
        }
    }
}
extension HexCoordinate: LosslessStringConvertible {
    @inlinable public init?(_ string: some StringProtocol) {
        guard
        let first: String.Index = string.indices.first else {
            return nil
        }

        let i: String.Index = string.index(after: first)

        switch string[first] {
        case "N":
            if  let coordinate: AxialCoordinate = .init(string[i...]) {
                self = .n(coordinate.q, coordinate.r)
                return
            }
        case "E":
            if  let φ: Int8 = .init(string[i...]) {
                self = .e(φ)
                return
            }
        case "S":
            if  let coordinate: AxialCoordinate = .init(string[i...]) {
                self = .s(coordinate.q, coordinate.r)
                return
            }
        case "X":
            self = .x
            return

        default:
            break
        }

        return nil
    }
}
extension HexCoordinate {
    public func neighbors(size z: Int8) -> [HexCoordinate] {
        switch self {
        case .x:
            return []

        case .n(let q, let r):
            return Self.neighbors(q: q, r: r, z: z, cis: HexCoordinate.n, trn: HexCoordinate.s)

        case .e(0):
            let (q, r): (Int8, Int8) = (z, 0)
            return [
                .n(q    , r - 1),  // t + v[2]
                .n(q - 1, r    ),  // t + v[3]
                .n(q - 1, r + 1),  // t + v[4]
                .s(q - 1, r + 1),  // t + v[4]
                .s(q - 1, r    ),  // t + v[3]
                .s(q    , r - 1),  // t + v[2]
            ]

        case .e(1):
            let (q, r): (Int8, Int8) = (z, -z)
            return [
                .n(q - 1, r    ),  // v[3]
                .n(q - 1, r + 1),  // v[4]
                .n(q    , r + 1),  // v[5]
                .s(q    , r + 1),  // v[5]
                .s(q - 1, r + 1),  // v[4]
                .s(q - 1, r    ),  // v[3]
            ]

        case .e(2):
            let (q, r): (Int8, Int8) = (0, -z)
            return [
                .n(q - 1, r + 1),  // v[4]
                .n(q    , r + 1),  // v[5]
                .n(q + 1, r    ),  // v[0]
                .s(q + 1, r    ),  // v[0]
                .s(q    , r + 1),  // v[5]
                .s(q - 1, r + 1),  // v[4]
            ]

        case .e(3):
            let (q, r): (Int8, Int8) = (-z, 0)
            return [
                .n(q    , r + 1),  // v[5]
                .n(q + 1, r    ),  // v[0]
                .n(q + 1, r - 1),  // v[1]
                .s(q + 1, r - 1),  // v[1]
                .s(q + 1, r    ),  // v[0]
                .s(q    , r + 1),  // v[5]
            ]

        case .e(4):
            let (q, r): (Int8, Int8) = (-z, z)
            return [
                .n(q + 1, r    ),  // v[0]
                .n(q + 1, r - 1),  // v[1]
                .n(q    , r - 1),  // v[2]
                .s(q    , r - 1),  // v[2]
                .s(q + 1, r - 1),  // v[1]
                .s(q + 1, r    ),  // v[0]
            ]

        case .e(5):
            let (q, r): (Int8, Int8) = (0, z)
            return [
                .n(q + 1, r - 1),  // v[1]
                .n(q    , r - 1),  // v[2]
                .n(q - 1, r    ),  // v[3]
                .s(q - 1, r    ),  // v[3]
                .s(q    , r - 1),  // v[2]
                .s(q + 1, r - 1),  // v[1]
            ]

        case .s(let q, let r):
            return Self.neighbors(q: q, r: r, z: z, cis: HexCoordinate.s, trn: HexCoordinate.n)

        default:
            return []
        }
    }

    private static func neighbors(
        q: Int8,
        r: Int8,
        z: Int8,
        cis: (Int8, Int8) -> HexCoordinate,
        trn: (Int8, Int8) -> HexCoordinate
    ) -> [HexCoordinate] {
        /// Cube coordinate basis vectors
        ///
        ///       1
        ///   2       0
        ///      >|<
        ///   3       5
        ///       4
        ///
        /// v[0] = ( 1,  0, -1)
        /// v[1] = ( 1, -1,  0)
        /// v[2] = ( 0, -1,  1)
        /// v[3] = (-1,  0,  1)
        /// v[4] = (-1,  1,  0)
        /// v[5] = ( 0,  1, -1)

        let s: Int8 = -q - r
        switch (q, r, s) {
        /// If one of the coordinates is ±z, the tile is an edge tile, which will never
        /// be axis-aligned (as those are equatorial)
        ///
        /// Most edge tiles have seven neighbors – the four normal axial neighbors
        /// on the same hemisphere, its twin in the other hemisphere, and the two
        /// axial neighbors of the twin tile that also happen to be edge tiles.
        ///
        /// If the tile has an equatorial neighbor (i.e., there is a basis vector that
        /// would yield an axis-aligned coordinate when added to its own coordinate),
        /// then it has six neighbors – the equatorial tile, its twin in the other
        /// hemisphere, the twin’s equatorial neighbor (which is the same tile as the
        /// first equatorial neighbor), the tile on the opposite side of the twin
        /// across from the equatorial neighbor, and the three remaining normal axial
        /// neighbors of that tile.

        ///          (  , -z,  1)     ( z,   , -1)
        ///          ( 1, -z,   )     ( z, -1,   )
        ///                        1
        ///     (-1,   ,  z)   2       0
        ///     (  , -1,  z)      >|<      (  ,  1, -z)
        ///                    3       5   ( 1,   , -z)
        ///                        4
        ///          (-z,  1,   )     (-1,  z,   )
        ///          (-z,   ,  1)     (  ,  z, -1)
        ///
        /// In the comments below, `t` is the vector (q, r, s) of the tile whose
        /// neighbors we are computing, and R(t, +θ) is a counterclockwise rotation
        /// of t by θ degrees around the origin.
        ///
        /// A(t) and B(t) are the two cases defined below.
        case (z, -1, _):
            // CASE A: `t` has an equatorial neighbor along v[0] axis
            //
            // Note that `e(_:_:)` interprets its arguments as multiples of `z`,
            // so `e(+1, -1)` means `e(+z, -z, scale: z)`.
            //
            // In all computations below, we omit the third cube coordinate.
            //
            // x[0] = cis(t + v[2]) = cis(q    , r - 1, s + 1)
            // x[1] = cis(t + v[3]) = cis(q - 1, r    , s + 1)
            // x[2] = cis(t + v[4]) = cis(q - 1, r + 1, s    )
            // x[3] = eqt(t + v[5]) = eqt(+z, 0, -z)
            // x[4] = trn(t + v[2]) = trn(q    , r - 1, s + 1) (across from v[5])
            // x[5] = trn(t) = trn(q, r, s) (twin tile)
            return [
                cis(q    , r - 1),  // t + v[2]
                cis(q - 1, r    ),  // t + v[3]
                cis(q - 1, r + 1),  // t + v[4]
                .e(+1,  0),         // t + v[5] (aka: +z, 0, -z)
                trn(q    , r    ),  // t        (twin tile)
                trn(q    , r - 1),  // t + v[2] (across from v[5])
            ]
        case (z, _, -1):
            // CASE B: `t` has an equatorial neighbor along v[1] axis
            //
            // x[0] = trn(t + v[5]) = trn(q    , r + 1, s - 1) (across from v[2])
            // x[1] = trn(t) = trn(q, r, s) (twin tile)
            // x[2] = eqt(t + v[2]) = eqt(+z, -z, 0)
            // x[3] = cis(t + v[3]) = cis(q - 1, r    , s + 1)
            // x[4] = cis(t + v[4]) = cis(q - 1, r + 1, s    )
            // x[5] = cis(t + v[5]) = cis(q    , r + 1, s - 1)
            return [
                trn(q    , r + 1),  // t + v[5] (across from v[2])
                trn(q    , r    ),  // t        (twin tile)
                .e(+1, -1),         // t + v[2] (aka: +z, -z, 0)
                cis(q - 1, r    ),  // t + v[3]
                cis(q - 1, r + 1),  // t + v[4]
                cis(q    , r + 1),  // t + v[5]
            ]
        case (z, _, _):
            // CASE C: no equatorial neighbor
            //
            // x[0] = cis(t + v[2]) = cis(q    , r - 1, s + 1)
            // x[1] = cis(t + v[3]) = cis(q - 1, r    , s + 1)
            // x[2] = cis(t + v[4]) = cis(q - 1, r + 1, s    )
            // x[3] = cis(t + v[5]) = cis(q    , r + 1, s - 1)
            // x[4] = trn(t + v[5]) = trn(q    , r + 1, s - 1) (across from v[2])
            // x[5] = trn(t) = trn(q, r, s) (twin tile)
            // x[6] = trn(t + v[2]) = trn(q    , r - 1, s + 1) (across from v[5])
            return [
                cis(q    , r - 1),  // t + v[2]
                cis(q - 1, r    ),  // t + v[3]
                cis(q - 1, r + 1),  // t + v[4]
                cis(q    , r + 1),  // t + v[5]
                trn(q    , r + 1),  // t + v[5] (across from v[2])
                trn(q    , r    ),  // t        (twin tile)
                trn(q    , r - 1),  // t + v[2] (across from v[5])
            ]

        case (_, -z, +1):
            // Rotate `t` -60°, apply CASE A, then rotate result +60°.
            // R(A(R(t, -60°)), +60°)
            //
            // R(t, -60°) = (-r, -s, -q)
            // R(t, +60°) = (-s, -q, -r)
            //
            // x[0] = cis(R((-r, -s, -q) + v[2]), +60°))
            //      = cis(R((-r, -s - 1, -q + 1), +60°))
            //      = cis(q - 1, r, s + 1)
            // x[1] = cis(R((-r, -s, -q) + v[3]), +60°))
            //      = cis(R((-r - 1, -s, -q + 1), +60°))
            //      = cis(q - 1, r + 1, s)
            // x[2] = cis(R((-r, -s, -q) + v[4]), +60°))
            //      = cis(R((-r - 1, -s + 1, -q), +60°))
            //      = cis(q, r + 1, s - 1)
            return [
                cis(q - 1, r    ),
                cis(q - 1, r + 1),
                cis(q    , r + 1),
                .e(1),
                trn(q    , r    ),
                trn(q - 1, r    ),
            ]
        case (+1, -z, _):
            // Rotate `t` -60°, apply CASE B, then rotate result +60°.
            // R(B(R(t, -60°)), +60°)
            //
            // x[3] = cis(R((-r, -s, -q) + v[3]), +60°))
            //      = cis(R((-r - 1, -s, -q + 1), +60°))
            //      = cis(q - 1, r + 1, s)
            // x[4] = cis(R((-r, -s, -q) + v[4]), +60°))
            //      = cis(R((-r - 1, -s + 1, -q), +60°))
            //      = cis(q, r + 1, s - 1)
            // x[5] = cis(R((-r, -s, -q) + v[5]), +60°))
            //      = cis(R((-r, -s + 1, -q - 1), +60°))
            //      = cis(q + 1, r, s - 1)
            return [
                trn(q + 1, r    ),
                trn(q    , r    ),
                .e(2),
                cis(q - 1, r + 1),
                cis(q    , r + 1),
                cis(q + 1, r    ),
            ]
        case (_, -z, _):
            // R(C(R(t, +60°)), -60°)
            //
            // x[0] = cis(R((-r, -s, -q) + v[2]), +60°))
            //      = cis(R((-r, -s - 1, -q + 1), +60°))
            //      = cis(q - 1, r, s + 1)
            // x[1] = cis(R((-r, -s, -q) + v[3]), +60°))
            //      = cis(R((-r - 1, -s, -q + 1), +60°))
            //      = cis(q - 1, r + 1, s)
            // x[2] = cis(R((-r, -s, -q) + v[4]), +60°))
            //      = cis(R((-r - 1, -s + 1, -q), +60°))
            //      = cis(q, r + 1, s - 1)
            // x[3] = cis(R((-r, -s, -q) + v[5]), +60°))
            //      = cis(R((-r, -s + 1, -q - 1), +60°))
            //      = cis(q + 1, r, s - 1)
            return [
                cis(q - 1, r    ),
                cis(q - 1, r + 1),
                cis(q    , r + 1),
                cis(q + 1, r    ),
                trn(q + 1, r    ),
                trn(q    , r    ),
                trn(q - 1, r    ),
            ]

        case (-1, _, z):
            // R(A(R(t, -120°)), +120°)
            //
            // R(t, -120°) = (s, q, r)
            // R(t, +120°) = (r, s, q)
            //
            // x[0] = cis(R((s, q, r) + v[2]), +120°))
            //      = cis(R((s, q - 1, r + 1), +120°))
            //      = cis(q - 1, r + 1, s)
            // x[1] = cis(R((s, q, r) + v[3]), +120°))
            //      = cis(R((s - 1, q, r + 1), +120°))
            //      = cis(q, r + 1, s - 1)
            // x[2] = cis(R((s, q, r) + v[4]), +120°))
            //      = cis(R((s - 1, q + 1, r), +120°))
            //      = cis(q + 1, r, s - 1)
            return [
                cis(q - 1, r + 1),
                cis(q    , r + 1),
                cis(q + 1, r    ),
                .e(0, -1),
                trn(q    , r    ),
                trn(q - 1, r + 1),
            ]
        case (_, -1, z):
            // R(B(R(t, -120°)), +120°)
            //
            // x[3] = cis(R((s, q, r) + v[3]), +120°))
            //      = cis(R((s - 1, q, r + 1), +120°))
            //      = cis(q, r + 1, s - 1)
            // x[4] = cis(R((s, q, r) + v[4]), +120°))
            //      = cis(R((s - 1, q + 1, r), +120°))
            //      = cis(q + 1, r, s - 1)
            // x[5] = cis(R((s, q, r) + v[5]), +120°))
            //      = cis(R((s, q + 1, r - 1), +120°))
            //      = cis(q + 1, r - 1, s)
            return [
                trn(q + 1, r - 1),
                trn(q    , r    ),
                .e(-1, 0),
                cis(q    , r + 1),
                cis(q + 1, r    ),
                cis(q + 1, r - 1),
            ]
        case (_, _, z):
            // R(C(R(t, -120°)), +120°)
            //
            // x[0] = cis(R((s, q, r) + v[2]), +120°))
            //      = cis(R((s, q - 1, r + 1), +120°))
            //      = cis(q - 1, r + 1, s)
            // x[1] = cis(R((s, q, r) + v[3]), +120°))
            //      = cis(R((s - 1, q, r + 1), +120°))
            //      = cis(q, r + 1, s - 1)
            // x[2] = cis(R((s, q, r) + v[4]), +120°))
            //      = cis(R((s - 1, q + 1, r), +120°))
            //      = cis(q + 1, r, s - 1)
            // x[3] = cis(R((s, q, r) + v[5]), +120°))
            //      = cis(R((s, q + 1, r - 1), +120°))
            //      = cis(q + 1, r - 1, s)
            return [
                cis(q - 1, r + 1),
                cis(q    , r + 1),
                cis(q + 1, r    ),
                cis(q + 1, r - 1),
                trn(q + 1, r - 1),
                trn(q    , r    ),
                trn(q - 1, r + 1),
            ]

        case (-z, +1, _):
            // R(A(R(t, ±180°)), ±180°) = -A(-t)
            return [
                cis(q    , r + 1),
                cis(q + 1, r    ),
                cis(q + 1, r - 1),
                .e(3),
                trn(q    , r    ),
                trn(q    , r + 1),
            ]
        case (-z, _, +1):
            // R(B(R(t, ±180°)), ±180°) = -B(-t)
            return [
                trn(q    , r - 1),
                trn(q    , r    ),
                .e(4),
                cis(q + 1, r    ),
                cis(q + 1, r - 1),
                cis(q    , r - 1),
            ]
        case (-z, _, _):
            // R(C(R(t, ±180°)), ±180°) = -C(-t)
            return [
                cis(q    , r + 1),
                cis(q + 1, r    ),
                cis(q + 1, r - 1),
                cis(q    , r - 1),
                trn(q    , r - 1),
                trn(q    , r    ),
                trn(q    , r + 1),
            ]

        case (_, z, -1):
            // R(A(R(t, +120°)), -120°)
            //
            // R(t, +120°) = (r, s, q)
            // R(t, -120°) = (s, q, r)
            //
            // x[0] = cis(R((r, s, q) + v[2]), -120°))
            //      = cis(R((r, s - 1, q + 1), -120°))
            //      = cis(q + 1, r, s - 1)
            // x[1] = cis(R((r, s, q) + v[3]), -120°))
            //      = cis(R((r - 1, s, q + 1), -120°))
            //      = cis(q + 1, r - 1, s)
            // x[2] = cis(R((r, s, q) + v[4]), -120°))
            //      = cis(R((r - 1, s + 1, q), -120°))
            //      = cis(q, r - 1, s + 1)
            return [
                cis(q + 1, r    ),
                cis(q + 1, r - 1),
                cis(q    , r - 1),
                .e(-1, +1),
                trn(q    , r    ),
                trn(q + 1, r    ),
            ]
        case (-1, z, _):
            // R(B(R(t, +120°)), -120°)
            //
            // x[3] = cis(R((r, s, q) + v[3]), -120°))
            //      = cis(R((r - 1, s, q + 1), -120°))
            //      = cis(q + 1, r - 1, s)
            // x[4] = cis(R((r, s, q) + v[4]), -120°))
            //      = cis(R((r - 1, s + 1, q), -120°))
            //      = cis(q, r - 1, s + 1)
            // x[5] = cis(R((r, s, q) + v[5]), -120°))
            //      = cis(R((r, s + 1, q - 1), -120°))
            //      = cis(q - 1, r, s + 1)
            return [
                trn(q - 1, r    ),
                trn(q    , r    ),
                .e(0, +1),
                cis(q + 1, r - 1),
                cis(q    , r - 1),
                cis(q - 1, r    ),
            ]
        case (_, z, _):
            // R(C(R(t, +120°)), -120°)
            //
            // x[0] = cis(R((r, s, q) + v[2]), -120°))
            //      = cis(R((r, s - 1, q + 1), -120°))
            //      = cis(q + 1, r, s - 1)
            // x[1] = cis(R((r, s, q) + v[3]), -120°))
            //      = cis(R((r - 1, s, q + 1), -120°))
            //      = cis(q + 1, r - 1, s)
            // x[2] = cis(R((r, s, q) + v[4]), -120°))
            //      = cis(R((r - 1, s + 1, q), -120°))
            //      = cis(q, r - 1, s + 1)
            // x[3] = cis(R((r, s, q) + v[5]), -120°))
            //      = cis(R((r, s + 1, q - 1), -120°))
            //      = cis(q - 1, r, s + 1)
            return [
                cis(q + 1, r    ),
                cis(q + 1, r - 1),
                cis(q    , r - 1),
                cis(q - 1, r    ),
                trn(q - 1, r    ),
                trn(q    , r    ),
                trn(q + 1, r    ),
            ]

        case (+1, _, -z):
            // R(A(R(t, +60°)), -60°)
            //
            // R(t, +60°) = (-s, -q, -r)
            // R(t, -60°) = (-r, -s, -q)
            //
            // x[0] = cis(R((-s, -q, -r) + v[2]), -60°))
            //      = cis(R((-s, -q - 1, -r + 1), -60°))
            //      = cis(q + 1, r - 1, s)
            // x[1] = cis(R((-s, -q, -r) + v[3]), -60°))
            //      = cis(R((-s - 1, -q, -r + 1), -60°))
            //      = cis(q, r - 1, s + 1)
            // x[2] = cis(R((-s, -q, -r) + v[4]), -60°))
            //      = cis(R((-s - 1, -q + 1, -r), -60°))
            //      = cis(q - 1, r, s + 1)
            return [
                cis(q + 1, r - 1),
                cis(q    , r - 1),
                cis(q - 1, r    ),
                .e(0, +1),
                trn(q    , r    ),
                trn(q + 1, r - 1),
            ]
        case (_, +1, -z):
            // R(B(R(t, +60°)), -60°)
            //
            // x[3] = cis(R((-s, -q, -r) + v[3]), -60°))
            //      = cis(R((-s - 1, -q, -r + 1), -60°))
            //      = cis(q, r - 1, s + 1)
            // x[4] = cis(R((-s, -q, -r) + v[4]), -60°))
            //      = cis(R((-s - 1, -q + 1, -r), -60°))
            //      = cis(q - 1, r, s + 1)
            // x[5] = cis(R((-s, -q, -r) + v[5]), -60°))
            //      = cis(R((-s, -q + 1, -r - 1), -60°))
            //      = cis(q - 1, r + 1, s)
            return [
                trn(q - 1, r + 1),
                trn(q    , r    ),
                .e(+1, 0),
                cis(q    , r - 1),
                cis(q - 1, r    ),
                cis(q - 1, r + 1),
            ]
        case (_, _, -z):
            // R(C(R(t, +60°)), -60°)
            //
            // x[0] = cis(R((-s, -q, -r) + v[2]), -60°))
            //      = cis(R((-s, -q - 1, -r + 1), -60°))
            //      = cis(q + 1, r - 1, s)
            // x[1] = cis(R((-s, -q, -r) + v[3]), -60°))
            //      = cis(R((-s - 1, -q, -r + 1), -60°))
            //      = cis(q, r - 1, s + 1)
            // x[2] = cis(R((-s, -q, -r) + v[4]), -60°))
            //      = cis(R((-s - 1, -q + 1, -r), -60°))
            //      = cis(q - 1, r, s + 1)
            // x[3] = cis(R((-s, -q, -r) + v[5]), -60°))
            //      = cis(R((-s, -q + 1, -r - 1), -60°))
            //      = cis(q - 1, r + 1, s)
            return [
                cis(q + 1, r - 1),
                cis(q    , r - 1),
                cis(q - 1, r    ),
                cis(q - 1, r + 1),
                trn(q - 1, r + 1),
                trn(q    , r    ),
                trn(q + 1, r - 1),
            ]

        /// If one of the coordinates is 0, and the other two are ±(z - 1), the tile is
        /// axis-aligned, inset 1 tile from the edge, and has one equatorial neighbor.
        case (z - 1, 0, _):
            return [
                cis(q + 1, r - 1),  // t + v[1]
                cis(q    , r - 1),  // t + v[2]
                cis(q - 1, r    ),  // t + v[3]
                cis(q - 1, r + 1),  // t + v[4]
                cis(q    , r + 1),  // t + v[5]
                .e(+1, 0),          // t + v[0] (aka: +z, 0, -z)
            ]

        case (z - 1, _, 0):
            return [
                cis(q    , r - 1),  // t + v[2]
                cis(q - 1, r    ),  // t + v[3]
                cis(q - 1, r + 1),  // t + v[4]
                cis(q    , r + 1),  // t + v[5]
                cis(q + 1, r    ),  // t + v[0]
                .e(+1, -1),         // t + v[1] (aka: +z, -z, 0)
            ]

        case (0, _, z - 1):
            return [
                cis(q - 1, r    ),  // t + v[3]
                cis(q - 1, r + 1),  // t + v[4]
                cis(q    , r + 1),  // t + v[5]
                cis(q + 1, r    ),  // t + v[0]
                cis(q + 1, r - 1),  // t + v[1]
                .e(0, -1),          // t + v[2] (aka: 0, -z, +z)
            ]

        case (_, 0, z - 1):
            return [
                cis(q - 1, r + 1),  // t + v[4]
                cis(q    , r + 1),  // t + v[5]
                cis(q + 1, r    ),  // t + v[0]
                cis(q + 1, r - 1),  // t + v[1]
                cis(q    , r - 1),  // t + v[2]
                .e(-1, 0),          // t + v[3] (aka: -z, 0, +z)
            ]

        case (_, z - 1, 0):
            return [
                cis(q    , r + 1),  // t + v[5]
                cis(q + 1, r    ),  // t + v[0]
                cis(q + 1, r - 1),  // t + v[1]
                cis(q    , r - 1),  // t + v[2]
                cis(q - 1, r    ),  // t + v[3]
                .e(-1, +1),         // t + v[4] (aka: -z, +z, 0)
            ]

        case (0, z - 1, _):
            return [
                cis(q + 1, r    ),  // t + v[0]
                cis(q + 1, r - 1),  // t + v[1]
                cis(q    , r - 1),  // t + v[2]
                cis(q - 1, r    ),  // t + v[3]
                cis(q - 1, r + 1),  // t + v[4]
                .e(0, +1),          // t + v[5] (aka: 0, +z, -z)
            ]

        default:
            // Normal axial neighbors
            return [
                cis(q + 1, r    ),  // t + v[0]
                cis(q + 1, r - 1),  // t + v[1]
                cis(q    , r - 1),  // t + v[2]
                cis(q - 1, r    ),  // t + v[3]
                cis(q - 1, r + 1),  // t + v[4]
                cis(q    , r + 1),  // t + v[5]
            ]
        }
    }
}
