import GameEconomy

extension InventorySnapshot.Consumed {
    struct Value {
        let input: ResourceInput
        let tradeable: Bool
        let tradeableDaysReserve: Int64
    }
}
