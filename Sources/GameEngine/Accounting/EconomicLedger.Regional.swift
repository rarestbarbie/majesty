import GameIDs

extension EconomicLedger {
    struct Regional<Crosstab>: Equatable, Hashable where Crosstab: Hashable {
        let location: Address
        let crosstab: Crosstab
    }
}
extension EconomicLedger.Regional: Sendable where Crosstab: Sendable {}
