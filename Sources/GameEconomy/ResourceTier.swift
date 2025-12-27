import GameIDs
import OrderedCollections
import RealModule

@frozen public struct ResourceTier: Equatable, Hashable {
    public let x: OrderedDictionary<Resource, Int64>
    /// Concavity weight factors, cached for performance.
    public let u: [Double]
    public let i: Int

    @inlinable public init(
        x: OrderedDictionary<Resource, Int64>,
        u: [Double],
        i: Int
    ) {
        self.u = u
        self.x = x
        self.i = i
    }
}
extension ResourceTier {
    @inlinable public static var empty: Self { .init(x: [:], u: [], i: 0) }

    @inlinable public init(segmented: [(Resource, Int64)], tradeable: [(Resource, Int64)]) {
        let count: Int = segmented.count + tradeable.count
        var x: OrderedDictionary<Resource, Int64> = .init(minimumCapacity: count)

        for (id, amount): (Resource, Int64) in segmented {
            x[id] = amount
        }

        let i: Int = x.elements.endIndex

        for (id, amount): (Resource, Int64) in tradeable {
            x[id] = amount
        }

        let u: [Double] = x.values.map { Double.sqrt(Double.init($0)) }

        self.init(x: x, u: u, i: i)
    }
}
extension ResourceTier {
    @inlinable public var segmented: Coefficients {
        .init(all: self.x.elements, u: self.u[..<self.i])
    }
    @inlinable public var tradeable: Coefficients {
        .init(all: self.x.elements, u: self.u[self.i...])
    }
}
