@frozen public struct AxialCoordinate: Equatable, Hashable, Sendable {
    public let q: Int8
    public let r: Int8

    @inlinable public init(q: Int8, r: Int8) {
        self.q = q
        self.r = r
    }
}
extension AxialCoordinate {
    /// Returns the equatorial coordinate of this axial coordinate, if it is a corner cell.
    @inlinable public func φ(_ z: Int8) -> Int8? {
        switch (self.q, self.r) {
        case ( z, -z): 0
        case ( 0, -z): 1
        case (-z,  0): 2
        case (-z,  z): 3
        case ( 0,  z): 4
        case ( z,  0): 5
        case ( _,  _): nil
        }
    }
}
extension AxialCoordinate: LosslessStringConvertible {
    @inlinable public init?(_ string: some StringProtocol) {
        guard
        let comma: String.Index = string.firstIndex(of: ","),
        let q: Int8 = .init(string[..<comma]),
        let r: Int8 = .init(string[string.index(after: comma)...]) else {
            return nil
        }

        self.init(q: q, r: r)
    }

    @inlinable public var description: String {
        "\(self.q),\(self.r)"
    }
}
