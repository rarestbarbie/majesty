import GameState

enum LegalEntity: Equatable, Hashable {
    case factory(FactoryID)
    case pop(PopID)
}
