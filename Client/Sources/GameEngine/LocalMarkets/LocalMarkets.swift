import GameEconomy

struct LocalMarkets<LEI> {
    private var markets: [Key: LocalMarket<LEI>]

    init(markets: [Key: LocalMarket<LEI>] = [:]) {
        self.markets = markets
    }
}
extension LocalMarkets {
    subscript(location: Address, resource: Resource) -> LocalMarket<LEI> {
        _read {
            yield  self.markets[.init(location: location, resource: resource), default: .init()]
        }
        _modify {
            yield &self.markets[.init(location: location, resource: resource), default: .init()]
        }
    }
}
extension LocalMarkets {
    mutating func turn(by turn: (Key, inout LocalMarket<LEI>) -> ()) {
        var i: [Key: LocalMarket<LEI>].Index = self.markets.startIndex
        while i < self.markets.endIndex {
            let id: Key = self.markets.keys[i]
            turn(id, &self.markets.values[i])
            i = self.markets.index(after: i)
        }
    }
}
