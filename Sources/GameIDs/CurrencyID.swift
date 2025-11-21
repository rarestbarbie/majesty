// todo: rename
public typealias Fiat = CurrencyID

@frozen public struct CurrencyID: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: Int16

    @inlinable public init(rawValue: Int16) {
        self.rawValue = rawValue
    }
}
extension CurrencyID: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        a.rawValue < b.rawValue
    }
}
extension CurrencyID: ExpressibleByIntegerLiteral {
    @inlinable public init(integerLiteral value: Int16) {
        self.init(rawValue: value)
    }
}
extension CurrencyID: CustomStringConvertible {
    @inlinable public var description: String { "\(self.rawValue)" }
}
extension CurrencyID: LosslessStringConvertible {
    @inlinable public init?(_ description: some StringProtocol) {
        guard let rawValue: Int16 = .init(description) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
