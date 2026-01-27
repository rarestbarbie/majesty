import GameIDs
import JavaScriptInterop

extension TileContext {
    struct ResidentPops {
        var list: [PopID]
    }
}
extension TileContext.ResidentPops {
    init() {
        self.init(list: [])
    }
}

extension TileContext.ResidentPops {
    mutating func startIndexCount() {
        // use the previous day’s counts to allocate capacity
        let list: Int = self.list.count

        self.list = []
        self.list.reserveCapacity(list)
    }

    mutating func addResidentCount(_ pop: Pop) {
        self.list.append(pop.id)
    }
}
