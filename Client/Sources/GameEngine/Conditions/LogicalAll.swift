@frozen public struct LogicalAll: Equatable, LogicalReduction {
    @inlinable public static var identity: Bool { true }

    public let predicate: Bool

    @inlinable init(predicate: Bool) {
        self.predicate = predicate
    }
}
extension LogicalAll: ExpressibleByBooleanLiteral {
    @inlinable public init(booleanLiteral: Bool) {
        self.init(predicate: booleanLiteral)
    }
}
extension LogicalAll: CustomStringConvertible {
    @inlinable public var description: String {
        self.predicate ? "All of the following" : "None of the following"
    }
}
