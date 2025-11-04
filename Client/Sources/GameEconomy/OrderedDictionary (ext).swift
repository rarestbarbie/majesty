import GameIDs
import OrderedCollections

extension OrderedDictionary where Key == Resource, Value: ResourceStockpile {
    @inlinable subscript(resource: Resource) -> Value {
        _read   { yield  self[resource, default: .init(id: resource)] }
        _modify { yield &self[resource, default: .init(id: resource)] }
    }

    @inlinable public mutating func sync(
        with coefficients: OrderedDictionary<Resource, Int64>,
        sync: (Int64, inout Value) -> Void
    ) {
        // Fast path: in-place update
        inplace: do {
            guard self.count == coefficients.count else {
                break inplace
            }
            for (i, (id, _)): (Value, (Resource, Int64)) in zip(self.values, coefficients)
                where i.id != id {
                break inplace
            }

            for (i, (_, amount)): (Int, (Resource, Int64)) in zip(
                    self.values.indices,
                    coefficients
                ) {
                sync(amount, &self.values[i])
            }

            return
        }

        // Slow path: the arrays are not the same length, or the resources do not match.
        var reallocated: Self = .init(minimumCapacity: coefficients.count)

        for (id, amount): (Resource, Int64) in coefficients {
            var value: Value = self[id] ?? .init(id: id)
            sync(amount, &value)
            reallocated[id] = value
        }

        self = reallocated
    }
}
