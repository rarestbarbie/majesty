import GameEconomy
import OrderedCollections

extension GeologicalMetadata {
    @frozen public struct Bonuses: Equatable, Hashable {
        public let weightNone: Int64
        public let weights: OrderedDictionary<Resource, GeologicalSpawnWeight>
    }
}
