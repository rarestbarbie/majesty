import GameIDs

extension Turn.Jobs {
    struct Hire<Market> where Market: Hashable {
        private var blocks: [Key: [PopJobOfferBlock]]

        init() {
            self.blocks = [:]
        }
    }
}
extension Turn.Jobs.Hire {
    subscript(market: Market, type: PopOccupation) -> [PopJobOfferBlock] {
        _read   { yield  self.blocks[Key.init(market: market, type: type), default: []] }
        _modify { yield &self.blocks[Key.init(market: market, type: type), default: []] }
    }
}
extension Turn.Jobs.Hire {
    mutating func turn(
        _ yield: (Key, inout [PopJobOfferBlock]) -> ()
    ) -> [(PopOccupation, [PopJobOfferBlock])] {
        var i: Dictionary<Key, [PopJobOfferBlock]>.Index = self.blocks.startIndex
        while i < self.blocks.endIndex {
            let key: Key = self.blocks.keys[i]
            ; {
                $0.sort { $0.bid < $1.bid }
                yield(key, &$0)
            } (&self.blocks.values[i])
            i = self.blocks.index(after: i)
        }
        defer { self.blocks = [:] }
        return self.blocks.map { ($0.type, $1) }
    }
}
