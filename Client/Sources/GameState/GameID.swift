@frozen public struct GameID<T>: RawRepresentable, Equatable, Hashable {
    public var rawValue: Int32

    @inlinable public init(rawValue: Int32) {
        self.rawValue = rawValue
    }
}
extension GameID {
    @inlinable public consuming func incremented() -> Self {
        return self.increment()
    }

    @inlinable public mutating func increment() -> Self {
        self.rawValue += 1
        return self
    }
}
extension GameID: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        a.rawValue < b.rawValue
    }
}
extension GameID: ExpressibleByIntegerLiteral {
    @inlinable public init(integerLiteral: Int32) {
        self.init(rawValue: integerLiteral)
    }
}
extension GameID: CustomStringConvertible {
    @inlinable public var description: String {
        "\(self.rawValue)"
    }
}
extension GameID: LosslessStringConvertible {
    @inlinable public init?(_ description: some StringProtocol) {
        guard let rawValue: Int32 = .init(description) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
