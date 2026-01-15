import GameIDs
import OrderedCollections

extension GeologicalAttributes {
    @frozen public struct Bonuses: Equatable, Hashable {
        public let weightNone: Int64
        public let weights: OrderedDictionary<Resource, GeologicalSpawnWeight>
    }
}
