@StringUnion @frozen public enum LEI: LosslessStringConvertible, Equatable, Hashable {
    @tag("F") case factory(FactoryID)
    @tag("P") case pop(PopID)
}
