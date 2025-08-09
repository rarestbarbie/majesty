@frozen public struct AxialCoordinate: Equatable, Hashable, Sendable {
    public let q: Int8
    public let r: Int8

    @inlinable public init(q: Int8, r: Int8) {
        self.q = q
        self.r = r
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
