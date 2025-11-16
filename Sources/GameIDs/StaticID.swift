public protocol StaticID: RawRepresentable<Int16>,
    LosslessStringConvertible,
    Comparable,
    Equatable,
    Hashable,
    Sendable {
    var rawValue: Int16 { get }
    init(rawValue: Int16)
}
extension StaticID {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        return a.rawValue < b.rawValue
    }
}
extension StaticID where Self: CustomStringConvertible {
    @inlinable public var description: String { "\(self.rawValue)" }
}
extension StaticID where Self: LosslessStringConvertible {
    @inlinable public init?(_ description: borrowing some StringProtocol) {
        guard let rawValue: Int16 = .init(copy description) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
