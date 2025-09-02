import GameEconomy

struct LocalMarkets<LegalEntity> {
    private var markets: [Key: LocalMarket<LegalEntity>]

    init(markets: [Key: LocalMarket<LegalEntity>] = [:]) {
        self.markets = markets
    }
}
extension LocalMarkets {
    subscript(location: Address, resource: Resource) -> LocalMarket<LegalEntity> {
        _read {
            yield  self.markets[.init(location: location, resource: resource), default: .init()]
        }
        _modify {
            yield &self.markets[.init(location: location, resource: resource), default: .init()]
        }
    }
}
extension LocalMarkets {
    mutating func turn(by turn: (Resource, inout LocalMarket<LegalEntity>) -> ()) {
        var i: [Key: LocalMarket<LegalEntity>].Index = self.markets.startIndex
        while i < self.markets.endIndex {
            let id: Key = self.markets.keys[i]
            turn(id.resource, &self.markets.values[i])
            i = self.markets.index(after: i)
        }
    }
}
