@frozen public struct Resource: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: Int16
    @inlinable public init(rawValue: Int16) { self.rawValue = rawValue }
}
extension Resource: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        return a.rawValue < b.rawValue
    }
}
extension Resource: CustomStringConvertible {
    @inlinable public var description: String { "\(self.rawValue)" }
}
extension Resource: LosslessStringConvertible {
    @inlinable public init?(_ description: some StringProtocol) {
        guard let rawValue: Int16 = .init(description) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}
