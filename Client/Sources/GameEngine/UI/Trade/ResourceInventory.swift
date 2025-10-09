import GameEconomy
import GameRules

struct ResourceInventory {
    private(set) var needs: [ResourceNeed]
    private(set) var sales: [ResourceSale]

    init() {
        needs = []
        sales = []
    }
}
extension ResourceInventory {
    mutating func reset(inputs: Int) {
        self.needs.removeAll(keepingCapacity: true)
        self.needs.reserveCapacity(inputs)
    }
    mutating func reset(outputs: Int) {
        self.sales.removeAll(keepingCapacity: true)
        self.sales.reserveCapacity(outputs)
    }

    mutating func update(
        from inputs: ResourceInputs,
        tier: ResourceTierIdentifier,
        currency: Fiat,
        location: Address,
        snapshot: borrowing GameSnapshot,
    ) {
        for (id, input): (Resource, TradeableInput) in inputs.tradeable {
            let market: Market? = snapshot.markets.tradeable[id / currency]
            self.needs.append(
                ResourceNeed.init(
                    label: snapshot.rules[id],
                    tier: tier,
                    unitsAcquired: input.unitsAcquired,
                    unitsConsumed: input.unitsConsumed,
                    unitsDemanded: input.unitsDemanded,
                    priceAtMarket: market?.history.last?.prices,
                    price: nil
                )
            )
        }
        for (id, input): (Resource, InelasticInput) in inputs.inelastic {
            let market: LocalMarket? = snapshot.markets.inelastic[location, id]
            self.needs.append(
                ResourceNeed.init(
                    label: snapshot.rules[id],
                    tier: tier,
                    unitsAcquired: input.unitsAcquired,
                    unitsConsumed: input.unitsPurchased,
                    unitsDemanded: input.unitsDemanded,
                    priceAtMarket: nil,
                    price: market?.price,
                )
            )
        }
    }
    mutating func update(
        from outputs: ResourceOutputs,
        currency: Fiat,
        location: Address,
        snapshot: borrowing GameSnapshot,
    ) {
        for (id, output): (Resource, TradeableOutput) in outputs.tradeable {
            let market: Market? = snapshot.markets.tradeable[id / currency]
            self.sales.append(
                ResourceSale.init(
                    label: snapshot.rules[output.id],
                    unitsProduced: output.unitsProduced,
                    unitsSold: output.unitsSold,
                    valueSold: output.valueSold,
                    priceAtMarket: market?.history.last?.prices,
                    price: nil
                )
            )
        }
        for (id, output): (Resource, InelasticOutput) in outputs.inelastic {
            let market: LocalMarket? = snapshot.markets.inelastic[location, id]
            self.sales.append(
                ResourceSale.init(
                    label: snapshot.rules[output.id],
                    unitsProduced: output.unitsProduced,
                    unitsSold: output.unitsSold,
                    valueSold: output.valueSold,
                    priceAtMarket: nil,
                    price: market?.price,
                )
            )
        }
    }
}
