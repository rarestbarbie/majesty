import GameEngine
import GameRules
import OrderedCollections

extension GameContext {
    struct Table<ElementContext> where ElementContext: RuntimeContext {
        private var index: OrderedDictionary<ElementContext.State.ID, ElementContext>

        init(index: OrderedDictionary<ElementContext.State.ID, ElementContext> = [:]) {
            self.index = index
        }
    }
}
extension GameContext.Table {
    init(
        states: [ElementContext.State],
        metadata: (ElementContext.State) -> ElementContext.Metadata?
    ) throws {
        var index: OrderedDictionary<ElementContext.State.ID, ElementContext> = [:]
        for state: ElementContext.State in states {
            try {
                if  let id: ElementContext.State.ID = $0?.state.id {
                    throw OrderedDictionaryCollisionError<ElementContext.State.ID>.init(id: id)
                }
                guard let type: ElementContext.Metadata = metadata(state) else {
                    throw RuntimeMetadataError<ElementContext.State.ID>.missing(state.id)
                }
                $0 = .init(type: type, state: state)
            } (&index[state.id])
        }
        self.init(index: index)
    }
}
extension GameContext.Table {
    var state: GameSnapshot.Table<ElementContext> { .init(index: self.index) }
}
extension GameContext.Table where ElementContext.State: Turnable {
    mutating func turnAll() {
        for i: Int in self.index.values.indices {
            self.index.values[i].turn()
        }
    }
}
extension GameContext.Table: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral: (Never, Never)...) {
        self.init(index: [:])
    }
}
extension GameContext.Table: Collection {
    var startIndex: Int {
        self.index.values.startIndex
    }

    var endIndex: Int {
        self.index.values.endIndex
    }

    func index(after i: Int) -> Int {
        self.index.values.index(after: i)
    }

    subscript(position: Int) -> ElementContext {
        get { self.index.values[position] }
        set { self.index.values[position] = newValue }
        // _modify { yield &self.index.values[position] }
    }
}
extension GameContext.Table {
    subscript(id: ElementContext.State.ID) -> ElementContext? {
        _read { yield self.index[id] }
        _modify { yield &self.index[id] }
    }

    mutating func append(_ element: ElementContext) -> Int {
        guard case (nil, let index): (ElementContext?, Int) = self.index.updateValue(
            element,
            forKey: element.state.id,
            insertingAt: self.index.values.endIndex
        ) else {
            fatalError("element with id \(element.state.id) already exists!")
        }

        return index
    }
}
