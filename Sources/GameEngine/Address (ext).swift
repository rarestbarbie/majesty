import GameIDs

extension Address {
    static func / <Crosstab>(self: Self, crosstab: Crosstab) -> EconomicLedger.Regional<Crosstab> {
        .init(location: self, crosstab: crosstab)
    }

    @available(*, unavailable, message: "tile must precede resource, did you mean to create 'LocalMarket.ID' instead?")
    static func / (resource: Resource, self: Self) -> EconomicLedger.Regional<Resource> {
        .init(location: self, crosstab: resource)
    }
}
