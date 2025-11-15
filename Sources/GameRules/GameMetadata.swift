public protocol GameMetadata: AnyObject, Identifiable, Sendable where ID: Sendable {
    var identity: SymbolAssignment<ID> { get }
    var title: String { get }
}
extension GameMetadata {
    @inlinable public var id: Self.ID { self.identity.code }

    @available(*, deprecated, renamed: "title")
    @inlinable public var name: String { self.identity.symbol.name }

    @inlinable public var title: String { self.identity.symbol.name }
    @inlinable public var symbol: Symbol { self.identity.symbol }
}

