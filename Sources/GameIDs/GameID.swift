public protocol GameID: RawRepresentable<Int32>,
    Equatable,
    Hashable,
    Comparable,
    CustomStringConvertible,
    LosslessStringConvertible,
    ExpressibleByIntegerLiteral {
    init(rawValue: Int32)
    var rawValue: Int32 { get set }
}
extension GameID {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        a.rawValue < b.rawValue
    }
}
extension GameID {
    @inlinable public init(integerLiteral: Int32) {
        self.init(rawValue: integerLiteral)
    }
}
extension GameID {
    @inlinable public var description: String {
        "\(self.rawValue)"
    }
    @inlinable public init?(_ description: some StringProtocol) {
        guard let rawValue: Int32 = .init(description) else {
            return nil
        }
        self.init(rawValue: rawValue)
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
