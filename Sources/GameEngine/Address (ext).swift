import GameIDs

extension Address {
    static func / (self: Self, resource: Resource) -> EconomicLedger.Regional {
        .init(resource: resource, location: self)
    }

    @available(*, unavailable, message: "tile must precede resource, did you mean to create 'LocalMarket.ID' instead?")
    static func / (resource: Resource, self: Self) -> EconomicLedger.Regional {
        .init(resource: resource, location: self)
    }
}
