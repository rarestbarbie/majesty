import OrderedCollections

@frozen public struct RuntimeContextTable<ElementContext> where ElementContext: RuntimeContext {
    @usableFromInline var index: OrderedDictionary<ElementContext.State.ID, ElementContext>

    @inlinable init(index: OrderedDictionary<ElementContext.State.ID, ElementContext> = [:]) {
        self.index = index
    }
}
extension RuntimeContextTable {
    public init(
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
extension RuntimeContextTable {
    @inlinable public var state: RuntimeStateTable<ElementContext> { .init(index: self.index) }
}
extension RuntimeContextTable {
    @inlinable public mutating func turn(by turn: (inout ElementContext) -> Void) {
        for i: Int in self.index.values.indices {
            turn(&self.index.values[i])
        }
    }

    /// Returns the **current** location of the element with the given ID, if it exists.
    /// This may change after items are deleted from the table, although indices are stable
    /// across insertions.
    @inlinable public mutating func find(id: ElementContext.State.ID) -> Int? {
        self.index.index(forKey: id)
    }
}
extension RuntimeContextTable: ExpressibleByDictionaryLiteral {
    @inlinable public init(dictionaryLiteral: (Never, Never)...) {
        self.init(index: [:])
    }
}
extension RuntimeContextTable: Collection {
    @inlinable public var startIndex: Int {
        self.index.values.startIndex
    }

    @inlinable public var endIndex: Int {
        self.index.values.endIndex
    }

    @inlinable public func index(after i: Int) -> Int {
        self.index.values.index(after: i)
    }

    @inlinable public subscript(position: Int) -> ElementContext {
        get { self.index.values[position] }
        set { self.index.values[position] = newValue }
        _modify { yield &self.index.values[position] }
    }
}
extension RuntimeContextTable {
    @inlinable public subscript(id: ElementContext.State.ID) -> ElementContext? {
        _read { yield self.index[id] }
        _modify { yield &self.index[id] }
    }

    @inlinable public mutating func append(_ element: ElementContext) -> Int {
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
