import GameIDs

extension EconomicLedger {
    struct National<Owner>: Equatable, Hashable where Owner: Hashable {
        let resource: Resource
        /// nil if tradeable
        let location: Address?
        let country: CountryID
        let owner: Owner
    }
}
extension EconomicLedger.National: Sendable where Owner: Sendable {}
