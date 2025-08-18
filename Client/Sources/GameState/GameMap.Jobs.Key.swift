import GameEngine
import GameRules

extension GameMap.Jobs {
    struct Key: Hashable {
        let location: Location
        let type: PopType
    }
}
