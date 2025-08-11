import GameEngine
import GameRules

extension Pop {
    struct Section: Equatable, Hashable, Sendable {
        let culture: String
        let type: PopType
        let home: Address
    }
}
