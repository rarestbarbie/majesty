import GameIDs
import GameRules

extension Pop {
    struct Section: Equatable, Hashable, Sendable {
        let type: PopType
        let tile: Address
    }
}
