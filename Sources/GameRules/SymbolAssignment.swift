@frozen public struct SymbolAssignment<ID>: Equatable,
    Hashable,
    Sendable where ID: Hashable & Sendable {
    @usableFromInline let code: ID
    @usableFromInline let symbol: Symbol

    @inlinable init(code: ID, symbol: Symbol) {
        self.code = code
        self.symbol = symbol
    }
}
