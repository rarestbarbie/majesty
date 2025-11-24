@Identifier(Int32.self) @frozen public struct BuildingID: GameID {}

extension BuildingID: LegalEntityIdentifier {
    @inlinable public var lei: LEI { .building(self) }
}
