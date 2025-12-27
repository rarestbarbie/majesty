import GameIDs
import OrderedCollections

extension ResourceTier {
    @frozen public struct Coefficients {
        @usableFromInline let all: OrderedDictionary<Resource, Int64>.Elements
        @usableFromInline let u: ArraySlice<Double>

        @inlinable init(
            all: OrderedDictionary<Resource, Int64>.Elements,
            u: ArraySlice<Double>,
        ) {
            self.all = all
            self.u = u
        }
    }
}
extension ResourceTier.Coefficients {
    @inlinable public var x: OrderedDictionary<Resource, Int64>.Elements.SubSequence {
        self.all[self.u.indices]
    }
}
extension ResourceTier.Coefficients: RandomAccessCollection {
    @inlinable public var startIndex: Int { self.u.startIndex }
    @inlinable public var endIndex: Int { self.u.endIndex }

    @inlinable public subscript(index: Int) -> (id: Resource, u: Double, x: Int64) {
        let (id, x): (Resource, Int64) = self.all[index]
        return (id: id, u: self.u[index], x: x)
    }
}
