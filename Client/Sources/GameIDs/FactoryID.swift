@Identifier(Int32.self) @frozen public struct FactoryID: GameID {}

extension FactoryID: LegalEntityIdentifier {
    @inlinable public var lei: LEI { .factory(self) }
}
