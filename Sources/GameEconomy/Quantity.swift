@frozen public struct Quantity<Unit> {
    public var amount: Int64
    public let unit: Unit

    @inlinable public init(amount: Int64, unit: Unit) {
        self.amount = amount
        self.unit = unit
    }
}
extension Quantity: Equatable where Unit: Equatable {}
extension Quantity: Hashable where Unit: Hashable {}
extension Quantity: Sendable where Unit: Sendable {}
