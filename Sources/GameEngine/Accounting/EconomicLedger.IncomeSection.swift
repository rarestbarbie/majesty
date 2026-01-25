import GameIDs

extension EconomicLedger {
    struct IncomeSection: Equatable, Hashable {
        let stratum: PopStratum
        let gender: Gender
        let region: Address
    }
}
