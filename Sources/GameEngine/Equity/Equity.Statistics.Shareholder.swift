import GameIDs

extension Equity.Statistics {
    struct Shareholder {
        let id: Owner
        let shares: Int64
        let bought: Int64
        let sold: Int64
        let culture: CultureID
        let region: Address
        let gender: Gender?
    }
}
extension Equity.Statistics.Shareholder: Sendable where Owner: Sendable {}
