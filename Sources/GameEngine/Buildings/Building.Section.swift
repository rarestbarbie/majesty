import GameIDs
import GameRules

extension Building {
    struct Section: Equatable, Hashable {
        let type: BuildingType
        let tile: Address
    }
}
