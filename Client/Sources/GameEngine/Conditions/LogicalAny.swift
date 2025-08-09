@frozen public struct LogicalAny: Equatable, LogicalReduction {
    @inlinable public static var identity: Bool { false }

    public let predicate: Bool

    @inlinable init(predicate: Bool) {
        self.predicate = predicate
    }
}
extension LogicalAny: ExpressibleByBooleanLiteral {
    @inlinable public init(booleanLiteral: Bool) {
        self.init(predicate: booleanLiteral)
    }
}
extension LogicalAny: CustomStringConvertible {
    @inlinable public var description: String {
        self.predicate ? "Any of the following" : "Unless all of the following"
    }
}
