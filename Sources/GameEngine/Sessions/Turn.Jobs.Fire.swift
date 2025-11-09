import GameIDs

extension Turn.Jobs {
    struct Fire {
        private var blocks: [Key: PopJobLayoffBlock]

        init() {
            self.blocks = [:]
        }
    }
}
extension Turn.Jobs.Fire {
    subscript(factory: FactoryID, type: PopType) -> PopJobLayoffBlock? {
        _read   { yield  self.blocks[.factory(type, factory)] }
        _modify { yield &self.blocks[.factory(type, factory)] }
    }
    subscript(mine: MineID, type: PopType) -> PopJobLayoffBlock? {
        _read   { yield  self.blocks[.mine(type, mine)] }
        _modify { yield &self.blocks[.mine(type, mine)] }
    }
}
extension Turn.Jobs.Fire {
    mutating func turn() -> [Key: PopJobLayoffBlock] {
        defer { self.blocks = [:] }
        return self.blocks
    }
}
