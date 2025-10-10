import GameIDs

extension GameMap.Jobs {
    struct Fire {
        private var blocks: [FactoryID: FactoryJobLayoffBlock]

        init() {
            self.blocks = [:]
        }
    }
}
extension GameMap.Jobs.Fire {
    subscript(factory: FactoryID) -> FactoryJobLayoffBlock? {
        _read   { yield  self.blocks[factory] }
        _modify { yield &self.blocks[factory] }
    }
}
extension GameMap.Jobs.Fire {
    mutating func turn() -> [FactoryID: FactoryJobLayoffBlock] {
        defer { self.blocks = [:] }
        return self.blocks
    }
}
