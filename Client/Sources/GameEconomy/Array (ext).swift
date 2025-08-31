import OrderedCollections

extension Array where Element: ResourceStockpile {
    @inlinable public mutating func sync(
        with coefficients: OrderedDictionary<Resource, Int64>,
        sync: (inout Element, Quantity<Resource>) -> Void
    ) {
        inplace: do {
            guard self.count == coefficients.count else {
                break inplace
            }
            for (i, (id, _)): (Element, (Resource, Int64)) in zip(self, coefficients)
                where i.id != id {
                break inplace
            }
            for (i, (id, amount)): (Int, (Resource, Int64)) in zip(self.indices, coefficients) {
                sync(&self[i], .init(amount: amount, unit: id))
            }

            return
        }

        // Slow path: the arrays are not the same length, or the resources do not match.
        let carryover: [Resource: Element] = self.reduce(into: [:]) {
            $0[$1.id] = $1
        }
        self = coefficients.map {
            var element: Element = carryover[$0] ?? .init(id: $0)
            sync(&element, .init(amount: $1, unit: $0))
            return element
        }
    }
}
