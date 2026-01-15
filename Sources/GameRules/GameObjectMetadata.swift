public protocol GameObjectMetadata: AnyObject, Symbolizable, Sendable {
    var title: String { get }
}
extension GameObjectMetadata {
    @inlinable public var title: String { self.identity.symbol.name }
}
