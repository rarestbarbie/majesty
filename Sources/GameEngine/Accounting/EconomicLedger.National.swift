import GameIDs

extension EconomicLedger {
    struct National<Crosstab>: Equatable, Hashable where Crosstab: Hashable {
        let country: CountryID
        let crosstab: Crosstab
    }
}
extension EconomicLedger.National: Sendable where Crosstab: Sendable {}
