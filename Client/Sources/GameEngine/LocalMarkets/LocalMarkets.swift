import GameEconomy
import GameState

struct LocalMarkets {
    private var markets: [Key: LocalMarket]

    init(markets: [Key: LocalMarket] = [:]) {
        self.markets = markets
    }
}
extension LocalMarkets {
    subscript(location: Address, resource: Resource) -> LocalMarket {
        _read {
            yield  self.markets[.init(location: location, resource: resource), default: .init()]
        }
        _modify {
            yield &self.markets[.init(location: location, resource: resource), default: .init()]
        }
    }
}
extension LocalMarkets {
    mutating func turn(by turn: (Key, inout LocalMarket) -> ()) {
        var i: [Key: LocalMarket].Index = self.markets.startIndex
        while i < self.markets.endIndex {
            let id: Key = self.markets.keys[i]
            turn(id, &self.markets.values[i])
            i = self.markets.index(after: i)
        }
    }
}
