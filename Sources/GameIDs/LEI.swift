@StringUnion @frozen public enum LEI: LosslessStringConvertible, Equatable, Hashable {
    @tag("B") case building(BuildingID)
    @tag("F") case factory(FactoryID)
    @tag("P") case pop(PopID)
}
