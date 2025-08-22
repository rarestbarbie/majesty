import Assert

extension Array where Element: ResourceStockpile {
    @inlinable public mutating func sync(
        with coefficients: [Quantity<Resource>],
        sync: (inout Element, Quantity<Resource>) -> Void
    ) {
        inplace: do {
            guard self.count == coefficients.count else {
                break inplace
            }
            for (i, c): (Element, Quantity<Resource>) in zip(self, coefficients)
                where i.id != c.unit {
                break inplace
            }
            for (i, c): (Int, Quantity<Resource>) in zip(self.indices, coefficients) {
                sync(&self[i], c)
            }

            return
        }

        // Slow path: the arrays are not the same length, or the resources do not match.
        let carryover: [Resource: Element] = self.reduce(into: [:]) {
            $0[$1.id] = $1
        }
        self = coefficients.map {
            var element: Element = carryover[$0.unit] ?? .init(id: $0.unit)
            sync(&element, $0)
            return element
        }
    }
}
extension [ResourceInput] {
    /// Returns the amount of funds actually spent.
    public mutating func buy(
        days stockpile: Int64,
        with budget: Int64,
        in currency: Fiat,
        on exchange: inout Exchange,
    ) -> Int64 {
        let weights: [Double] = self.map {
            Double.init($0.needed) * exchange.price(of: $0.id, in: currency)
        }
        guard let budgets: [Int64] = weights.distribute(budget) else {
            return 0
        }

        var funds: Int64 = budget

        for i: Int in self.indices {
            funds -= self[i].buy(days: stockpile, with: budgets[i], in: currency, on: &exchange)
        }

        #assert(
            0 ... budget ~= funds,
            """
            Spending is out of bounds: \(funds) not in [0, \(budget)] ?!?!
            Inputs: \(self)
            Budgets: \(budgets)
            """
        )

        return budget - funds
    }
}
extension [ResourceOutput] {
    /// Returns the amount of funds actually received.
    public mutating func sell(
        in currency: Fiat,
        on exchange: inout Exchange,
    ) -> Int64 {
        self.indices.reduce(into: 0) {
            $0 += self[$1].sell(in: currency, on: &exchange)
        }
    }
}
