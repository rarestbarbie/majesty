@StringUnion @frozen public enum LEI: LosslessStringConvertible, Equatable, Hashable, Sendable {
    @tag("R") case reserve(CountryID)

    @tag("B") case building(BuildingID)
    @tag("F") case factory(FactoryID)
    @tag("P") case pop(PopID)
}
