import GameIDs

extension GameMap.Jobs {
    struct Fire {
        private var blocks: [Key: PopJobLayoffBlock]

        init() {
            self.blocks = [:]
        }
    }
}
extension GameMap.Jobs.Fire {
    subscript(factory: FactoryID, type: PopType) -> PopJobLayoffBlock? {
        _read   { yield  self.blocks[.factory(type, factory)] }
        _modify { yield &self.blocks[.factory(type, factory)] }
    }
    subscript(mine: MineID, type: PopType) -> PopJobLayoffBlock? {
        _read   { yield  self.blocks[.mine(type, mine)] }
        _modify { yield &self.blocks[.mine(type, mine)] }
    }
}
extension GameMap.Jobs.Fire {
    mutating func turn() -> [Key: PopJobLayoffBlock] {
        defer { self.blocks = [:] }
        return self.blocks
    }
}
