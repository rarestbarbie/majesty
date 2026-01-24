@StringUnion @frozen public enum LEI: LosslessStringConvertible, Sendable {
    @tag("R") case reserve(CountryID)

    @tag("B") case building(BuildingID)
    @tag("F") case factory(FactoryID)
    @tag("P") case pop(PopID)
}
extension LEI: Equatable {
    @inlinable public static func == (a: Self, b: Self) -> Bool {
        switch (a, b) {
        case (.reserve(let a), .reserve(let b)): a == b
        case (.building(let a), .building(let b)): a == b
        case (.factory(let a), .factory(let b)): a == b
        case (.pop(let a), .pop(let b)): a == b
        default: false
        }
    }
}
extension LEI: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) {
        switch self {
        case .reserve(let id):
            hasher.combine(0)
            hasher.combine(id)
        case .building(let id):
            hasher.combine(1)
            hasher.combine(id)
        case .factory(let id):
            hasher.combine(2)
            hasher.combine(id)
        case .pop(let id):
            hasher.combine(3)
            hasher.combine(id)
        }
    }
}
