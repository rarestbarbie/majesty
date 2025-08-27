import GameRules
import GameState

extension GameMap.Jobs {
    struct Hire<Location> where Location: Hashable {
        private var blocks: [Key: [FactoryJobOfferBlock]]

        init() {
            self.blocks = [:]
        }
    }
}
extension GameMap.Jobs.Hire {
    subscript(location: Location, type: PopType) -> [FactoryJobOfferBlock] {
        _read   { yield  self.blocks[Key.init(location: location, type: type), default: []] }
        _modify { yield &self.blocks[Key.init(location: location, type: type), default: []] }
    }
}
extension GameMap.Jobs.Hire {
    mutating func turn(
        _ yield: (Key, inout [FactoryJobOfferBlock]) -> ()
    ) -> [(PopType, [FactoryJobOfferBlock])] {
        var i: Dictionary<Key, [FactoryJobOfferBlock]>.Index = self.blocks.startIndex
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
