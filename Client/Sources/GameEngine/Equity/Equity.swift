import GameState

struct Equity {
    private(set) var owners: [(id: PopID, count: Int64)]
    private(set) var shares: Int64

    init() {
        self.owners = []
        self.shares = 0
    }
}
extension Equity {
    mutating func count(pop: PopID, shares: Int64) {
        self.owners.append((pop, shares))
        self.shares += shares
    }
}
