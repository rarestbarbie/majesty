public protocol Sectionable<Section>: Identifiable where ID: GameID {
    associatedtype Section: Hashable
    var section: Section { get }
    init(id: ID, section: Section)
}
