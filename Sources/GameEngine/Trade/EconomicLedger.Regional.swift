import GameIDs

extension EconomicLedger {
    struct Regional: Equatable, Hashable {
        let resource: Resource
        let location: Address
    }
}
