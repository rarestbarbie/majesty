import Color
import GameIDs
import GameEconomy
import OrderedCollections

@frozen @usableFromInline struct PopAttributes {
    @usableFromInline var l: ResourceTier?
    @usableFromInline var e: ResourceTier?
    @usableFromInline var x: ResourceTier?
    @usableFromInline var output: ResourceTier?

    @inlinable init(
        l: ResourceTier?,
        e: ResourceTier?,
        x: ResourceTier?,
        output: ResourceTier?
    ) {
        self.l = l
        self.e = e
        self.x = x
        self.output = output
    }
}
extension PopAttributes {
    @inlinable static var empty: PopAttributes {
        .init(
            l: nil,
            e: nil,
            x: nil,
            output: nil
        )
    }
}
extension PopAttributes {
    @inlinable static func |= (self: inout Self, next: Self) {
        self.l = next.l ?? self.l
        self.e = next.e ?? self.e
        self.x = next.x ?? self.x
        self.output = next.output ?? self.output
    }
}
