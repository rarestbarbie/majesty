import GameIDs

extension Mine {
    struct Section: Equatable, Hashable {
        let type: MineType
        let tile: Address
    }
}
