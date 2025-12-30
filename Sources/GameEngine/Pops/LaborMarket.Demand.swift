import GameIDs

extension LaborMarket {
    struct Demand<Key> where Key: LaborMarketID {
        private var jobs: [Key: [PopJobOfferBlock]]
    }
}
extension LaborMarket.Demand: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral: (Never, Never)...) {
        self.init(jobs: [:])
    }
}
extension LaborMarket.Demand {
    subscript(market: Key) -> [PopJobOfferBlock] {
        _read   { yield  self.jobs[market, default: []] }
        _modify { yield &self.jobs[market, default: []] }
    }
}
extension LaborMarket.Demand {
    mutating func turn(
        _ yield: (Key, inout [PopJobOfferBlock]) -> ()
    ) -> [(PopOccupation, [PopJobOfferBlock])] {
        var i: Dictionary<Key, [PopJobOfferBlock]>.Index = self.jobs.startIndex
        while i < self.jobs.endIndex {
            let key: Key = self.jobs.keys[i]
            ; {
                $0.sort { $0.bid < $1.bid }
                yield(key, &$0)
            } (&self.jobs.values[i])
            i = self.jobs.index(after: i)
        }
        defer { self.jobs = [:] }
        return self.jobs.map { ($0.type, $1) }
    }
}
