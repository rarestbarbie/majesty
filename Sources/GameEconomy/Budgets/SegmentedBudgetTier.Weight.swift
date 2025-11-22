import GameIDs

extension SegmentedBudgetTier {
    @frozen public struct Weight {
        let id: Resource
        let unitsToPurchase: Int64
        let units: Int64
        let value: Int64
    }
}
