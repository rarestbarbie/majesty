@frozen @usableFromInline struct AxialCoordinate: Equatable, Hashable, Sendable {
    @usableFromInline let q: Int8
    @usableFromInline let r: Int8

    @inlinable init(q: Int8, r: Int8) {
        self.q = q
        self.r = r
    }
}
extension AxialCoordinate {
    /// Returns the equatorial coordinate of this axial coordinate, if it is a corner cell.
    @inlinable func φ(_ z: Int8) -> Int8? {
        switch (self.q, self.r) {
        case ( z,  0): 0
        case ( z, -z): 1
        case ( 0, -z): 2
        case (-z,  0): 3
        case (-z,  z): 4
        case ( 0,  z): 5
        case ( _,  _): nil
        }
    }

    @inlinable init(φ: Int8, z: Int8) {
        let q: Int8
        let r: Int8

        switch φ {
        case 0: (q, r) = ( z,  0)
        case 1: (q, r) = ( z, -z)
        case 2: (q, r) = ( 0, -z)
        case 3: (q, r) = (-z,  0)
        case 4: (q, r) = (-z,  z)
        case _: (q, r) = ( 0,  z)
        }

        self.init(q: q, r: r)
    }
}
extension AxialCoordinate: LosslessStringConvertible {
    @inlinable init?(_ string: some StringProtocol) {
        guard
        let comma: String.Index = string.firstIndex(of: ","),
        let q: Int8 = .init(string[..<comma]),
        let r: Int8 = .init(string[string.index(after: comma)...]) else {
            return nil
        }

        self.init(q: q, r: r)
    }

    @inlinable var description: String {
        "\(self.q),\(self.r)"
    }
}
