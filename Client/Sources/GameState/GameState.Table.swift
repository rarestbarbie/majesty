import GameEngine
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections

extension GameState {
    /// A read-only view of ``GameContext.Table``, which only permits access to the state of
    /// each object.
    struct Table<ElementContext> where ElementContext: RuntimeContext {
        let index: OrderedDictionary<ElementContext.State.ID, ElementContext>

        init(index: OrderedDictionary<ElementContext.State.ID, ElementContext>) {
            self.index = index
        }
    }
}
extension GameState.Table: Equatable where ElementContext.State: Equatable {
    static func == (a: Self, b: Self) -> Bool { a.elementsEqual(b) }
}
extension GameState.Table: Hashable where ElementContext.State: Hashable {
    func hash(into hasher: inout Hasher) {
        for state: ElementContext.State in self {
            state.hash(into: &hasher)
        }
    }
}
extension GameState.Table: Collection {
    var startIndex: Int {
        self.index.values.startIndex
    }

    var endIndex: Int {
        self.index.values.endIndex
    }

    func index(after i: Int) -> Int {
        self.index.values.index(after: i)
    }

    subscript(position: Int) -> ElementContext.State {
        self.index.values[position].state
    }
}
extension GameState.Table {
    subscript(id: ElementContext.State.ID) -> ElementContext.State? {
        self.index[id]?.state
    }
}
