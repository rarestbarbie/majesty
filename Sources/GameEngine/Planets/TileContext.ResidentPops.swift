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
        self.list.resetUsingHint()
    }

    mutating func addResidentCount(_ pop: Pop) {
        self.list.append(pop.id)
    }
}
