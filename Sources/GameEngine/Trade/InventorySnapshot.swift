import GameEconomy
import GameIDs
import OrderedCollections

struct InventorySnapshot {
    private let consumed: [Consumed.ID: Consumed.Value]
    private let produced: [Produced.ID: Produced.Value]
}
extension InventorySnapshot {
    static func building(_ building: Building) -> Self { .inventory(building.inventory) }

    static func factory(_ factory: Factory) -> Self { .inventory(factory.inventory) }

    static func pop(_ pop: Pop) -> Self {
        .init(
            consumed: Self.consumption(pop.inventory),
            produced: Self.production(pop.inventory.out, mines: pop.mines)
        )
    }
}
extension InventorySnapshot {
    private static func consumption(
        _ inventory: Inventory
    ) -> [Consumed.ID: Consumed.Value] {
        var consumption: [Consumed.ID: Consumed.Value] = .init(
            minimumCapacity: inventory.l.count + inventory.e.count + inventory.x.count
        )

        inventory.l.snapshot(into: &consumption, as: Consumed.ID.l(_:))
        inventory.e.snapshot(into: &consumption, as: Consumed.ID.e(_:))
        inventory.x.snapshot(into: &consumption, as: Consumed.ID.x(_:))

        return consumption
    }
    private static func production(
        _ out: ResourceOutputs
    ) -> [Produced.ID: Produced.Value] {
        var production: [Produced.ID: Produced.Value] = .init(minimumCapacity: out.count)
        out.snapshot(into: &production, as: Produced.ID.o(_:))
        return production
    }
    private static func production(
        _ out: ResourceOutputs,
        mines: OrderedDictionary<MineID, MiningJob>
    ) -> [Produced.ID: Produced.Value] {
        var production: [Produced.ID: Produced.Value] = .init(
            minimumCapacity: mines.values.reduce(out.count) { $0 + $1.out.count }
        )
        out.snapshot(into: &production, as: Produced.ID.o(_:))
        for mine: MiningJob in mines.values {
            mine.out.snapshot(into: &production) { .m(mine.id / $0) }
        }
        return production
    }

    private static func inventory(_ inventory: Inventory) -> Self {
        .init(
            consumed: Self.consumption(inventory),
            produced: Self.production(inventory.out)
        )
    }
}
extension InventorySnapshot {
    subscript(id: Consumed.ID) -> Consumed? {
        self.consumed[id].map { .init(id: id, value: $0) }
    }
    subscript(id: Produced.ID) -> Produced? {
        self.produced[id].map { .init(id: id, value: $0) }
    }
}
extension InventorySnapshot {
    func consumption(where predicate: (Consumed.ID) -> Bool) -> [Consumed] {
        var snapshots: [Consumed] = []
        ;   snapshots.reserveCapacity(self.consumed.keys.count(where: predicate))
        for (key, value): (Consumed.ID, Consumed.Value) in self.consumed
            where predicate(key) {
            snapshots.append(.init(id: key, value: value))
        }
        snapshots.sort { $0.input.id < $1.input.id }
        return snapshots
    }
    func production() -> [Produced] {
        var snapshots: [Produced] = self.produced.map { .init(id: $0.key, value: $0.value) }
        ;   snapshots.sort { $0.output.id < $1.output.id }
        return snapshots
    }

    func valueConsumed(tier: ResourceTierIdentifier) -> Int64 {
        self.consumed.reduce(into: 0) {
            if tier ~= $1.key {
                $0 += $1.value.input.valueConsumed
            }
        }
    }
}
