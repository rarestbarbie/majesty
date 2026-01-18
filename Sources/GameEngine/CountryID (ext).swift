import GameIDs

extension CountryID {
    static func / <Crosstab>(self: Self, crosstab: Crosstab) -> EconomicLedger.National<Crosstab> {
        .init(country: self, crosstab: crosstab)
    }
}
