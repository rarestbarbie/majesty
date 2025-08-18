import GameRules
import GameState

extension GameMap.Jobs {
    struct Key: Hashable {
        let location: Location
        let type: PopType
    }
}
