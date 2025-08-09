import GameEngine

protocol Sectionable<Section>: Identifiable<GameID<Self>> {
    associatedtype Section: Hashable
    var section: Section { get }
    init(id: GameID<Self>, section: Section)
}
