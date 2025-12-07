import GameIDs

extension Equity.Statistics {
    struct Shareholder {
        let id: Owner
        let shares: Int64
        let bought: Int64
        let sold: Int64
        let country: CountryID
        let culture: CultureID?
    }
}
extension Equity.Statistics.Shareholder: Sendable where Owner: Sendable {}
