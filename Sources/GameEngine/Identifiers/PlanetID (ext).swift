import GameIDs
import GameTerrain

extension PlanetID: PersistentExclusiveSelectionFilter {
    typealias Subject = TileSnapshot
}
