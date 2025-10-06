@Identifier(Int32.self) @frozen public struct PopID: GameID {}

extension PopID: LegalEntityIdentifier {
    @inlinable public var lei: LEI { .pop(self) }
}
