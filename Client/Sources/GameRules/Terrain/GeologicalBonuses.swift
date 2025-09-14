import GameEconomy
import OrderedCollections

@frozen public struct GeologicalBonuses: Equatable, Hashable {
    public let chanceNone: Int64
    public let list: OrderedDictionary<Resource, GeologicalSpawnWeight>
}
