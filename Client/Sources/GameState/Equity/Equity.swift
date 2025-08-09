import GameEngine

struct Equity {
    private(set) var owners: [(id: GameID<Pop>, count: Int64)]
    private(set) var shares: Int64

    init() {
        self.owners = []
        self.shares = 0
    }
}
extension Equity {
    mutating func count(pop: GameID<Pop>, shares: Int64) {
        self.owners.append((pop, shares))
        self.shares += shares
    }
}
