public protocol Symbolizable: Identifiable where ID: Sendable {
    var identity: SymbolAssignment<ID> { get }
}
extension Symbolizable {
    @inlinable public var id: Self.ID { self.identity.code }
    @inlinable public var symbol: Symbol { self.identity.symbol }
}
