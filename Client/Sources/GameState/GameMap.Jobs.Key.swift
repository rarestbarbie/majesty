import GameEngine
import GameRules

extension GameMap.Jobs {
    struct Key: Hashable {
        let on: GameID<Planet>
        let type: PopType
    }
}
