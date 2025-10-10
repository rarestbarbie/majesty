import GameIDs
import GameRules

extension Factory {
    struct Section: Equatable, Hashable {
        let type: FactoryType
        let tile: Address
    }
}
