import GameState
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections

extension GameSnapshot {
    /// A read-only view of ``GameContext.Table``, which only permits access to the state of
    /// each object.
    struct Table<ElementContext> where ElementContext: RuntimeContext {
        let index: OrderedDictionary<ElementContext.State.ID, ElementContext>

        init(index: OrderedDictionary<ElementContext.State.ID, ElementContext>) {
            self.index = index
        }
    }
}
extension GameSnapshot.Table: Equatable where ElementContext.State: Equatable {
    static func == (a: Self, b: Self) -> Bool { a.elementsEqual(b) }
}
extension GameSnapshot.Table: Hashable where ElementContext.State: Hashable {
    func hash(into hasher: inout Hasher) {
        for state: ElementContext.State in self {
            state.hash(into: &hasher)
        }
    }
}
extension GameSnapshot.Table: Collection {
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
extension GameSnapshot.Table {
    subscript(id: ElementContext.State.ID) -> ElementContext.State? {
        self.index[id]?.state
    }
}
