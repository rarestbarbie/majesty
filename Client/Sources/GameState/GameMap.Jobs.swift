import GameEngine
import GameRules

extension GameMap {
    struct Jobs {
        private(set) var blocks: [Key: [FactoryJobOfferBlock]]

        init() {
            self.blocks = [:]
        }
    }
}
extension GameMap.Jobs {
    subscript(planet: GameID<Planet>, type: PopType) -> [FactoryJobOfferBlock] {
        _read   { yield  self.blocks[Key.init(on: planet, type: type), default: []] }
        _modify { yield &self.blocks[Key.init(on: planet, type: type), default: []] }
    }
}
extension GameMap.Jobs {
    mutating func turn(_ yield: (Key, inout [FactoryJobOfferBlock]) -> ()) -> Self {
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
        return self
    }
}
