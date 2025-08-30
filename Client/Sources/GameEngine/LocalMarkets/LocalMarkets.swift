struct LocalMarkets<LegalEntity> {
    private var markets: [Key: LocalMarket<LegalEntity>]
}
extension LocalMarkets {
    subscript(location: Address, resource: LocalResource) -> LocalMarket<LegalEntity> {
        _read {
            yield  self.markets[.init(location: location, resource: resource), default: .init()]
        }
        _modify {
            yield &self.markets[.init(location: location, resource: resource), default: .init()]
        }
    }
}
