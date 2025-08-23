@frozen public struct Fiat: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: Int16

    @inlinable public init(rawValue: Int16) {
        self.rawValue = rawValue
    }
}
extension Fiat: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        a.rawValue < b.rawValue
    }
}
extension Fiat: ExpressibleByIntegerLiteral {
    @inlinable public init(integerLiteral value: Int16) {
        self.init(rawValue: value)
    }
}
extension Fiat: CustomStringConvertible {
    @inlinable public var description: String { "\(self.rawValue)" }
}
extension Fiat: LosslessStringConvertible {
    @inlinable public init?(_ description: some StringProtocol) {
        guard let rawValue: Int16 = .init(description) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
extension Fiat {
    @inlinable public static func / (a: Self, b: Self) -> Market.AssetPair {
        .init(.fiat(a), .fiat(b))
    }

    @inlinable static func / (a: Self, b: Market.Asset) -> Market.AssetPair {
        .init(.fiat(a), b)
    }

    @inlinable static func / (a: Market.Asset, b: Self) -> Market.AssetPair {
        .init(a, .fiat(b))
    }
}
extension Fiat {
    @inlinable public static func / (a: Self, b: Resource) -> Market.AssetPair {
        a / .good(b)
    }

    @inlinable public static func / (a: Resource, b: Self) -> Market.AssetPair {
        .good(a) / b
    }
}
