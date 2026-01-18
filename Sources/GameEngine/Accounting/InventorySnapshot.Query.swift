extension InventorySnapshot {
    enum Query {
        case consumed(Consumed.ID)
        case produced(Produced.ID)
    }
}
