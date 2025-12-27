import GameIDs
import OrderedCollections

extension OrderedDictionary where Key == Resource, Value: ResourceStockpile {
    @inlinable subscript(resource: Resource) -> Value {
        _read   { yield  self[resource, default: .init(id: resource)] }
        _modify { yield &self[resource, default: .init(id: resource)] }
    }

    mutating func sync(
        with coefficients: [Quantity<Resource>],
        sync: (Int64, inout Value) -> Void
    ) {
        // Fast path: in-place update
        inplace: do {
            guard self.count == coefficients.count else {
                break inplace
            }
            for (i, c): (Value, Quantity<Resource>) in zip(self.values, coefficients)
                where i.id != c.unit {
                break inplace
            }

            for (i, c): (Int, Quantity<Resource>) in zip(self.values.indices, coefficients) {
                sync(c.amount, &self.values[i])
            }

            return
        }

        // Slow path: the arrays are not the same length, or the resources do not match.
        var reallocated: Self = .init(minimumCapacity: coefficients.count)

        for c: Quantity<Resource> in coefficients {
            var value: Value = self[c.unit] ?? .init(id: c.unit)
            sync(c.amount, &value)
            reallocated[c.unit] = value
        }

        self = reallocated
    }
}
