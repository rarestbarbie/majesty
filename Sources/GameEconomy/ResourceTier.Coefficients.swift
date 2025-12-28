import GameIDs
import OrderedCollections

extension ResourceTier {
    @frozen public struct Coefficients {
        public let x: ArraySlice<Quantity<Resource>>

        @inlinable init(x: ArraySlice<Quantity<Resource>>) {
            self.x = x
        }
    }
}
extension ResourceTier.Coefficients: RandomAccessCollection {
    @inlinable public var startIndex: Int { self.x.startIndex }
    @inlinable public var endIndex: Int { self.x.endIndex }

    @inlinable public subscript(index: Int) -> (id: Resource, amount: Int64) {
        let x: Quantity<Resource> = self.x[index]
        return (x.unit, x.amount)
    }
}
