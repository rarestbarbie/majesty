import OrderedCollections

public final class Object<Value> where Value: ~Copyable {
    public var context: Value

    @inlinable init(context: consuming Value) {
        self.context = context
    }
}

@frozen public struct RuntimeContextTable<ElementContext> where ElementContext: RuntimeContext & ~Copyable {
    @usableFromInline var index: OrderedDictionary<ElementContext.State.ID, Object<ElementContext>>

    @inlinable init(index: OrderedDictionary<ElementContext.State.ID, Object<ElementContext>> = [:]) {
        self.index = index
    }
}
extension RuntimeContextTable where ElementContext: ~Copyable {
    public init(
        states: [ElementContext.State],
        metadata: (ElementContext.State) -> ElementContext.Metadata?
    ) throws {
        var index: OrderedDictionary<ElementContext.State.ID, Object<ElementContext>> = [:]
        for state: ElementContext.State in states {
            try {
                if  let id: ElementContext.State.ID = $0?.context.state.id {
                    throw OrderedDictionaryCollisionError<ElementContext.State.ID>.init(id: id)
                }
                guard let type: ElementContext.Metadata = metadata(state) else {
                    throw RuntimeMetadataError<ElementContext.State.ID>.missing(state.id)
                }
                $0 = .init(context: .init(type: type, state: state))
            } (&index[state.id])
        }
        self.init(index: index)
    }
}
extension RuntimeContextTable where ElementContext: ~Copyable {
    @inlinable public mutating func turn(by turn: (inout ElementContext) -> Void) {
        for i: Int in self.index.values.indices {
            turn(&self.index.values[i].context)
        }
    }

    /// Returns the **current** location of the element with the given ID, if it exists.
    /// This may change after items are deleted from the table, although indices are stable
    /// across insertions.
    @available(*, deprecated)
    @inlinable public mutating func find(id: ElementContext.State.ID) -> Int? {
        self.index.index(forKey: id)
    }

    @inlinable public var state: RuntimeStateTable<ElementContext> { .init(index: self.index) }
}
extension RuntimeContextTable: ExpressibleByDictionaryLiteral where ElementContext: ~Copyable {
    @inlinable public init(dictionaryLiteral: (Never, Never)...) {
        self.init(index: [:])
    }
}
extension RuntimeContextTable: Collection where ElementContext: ~Copyable {
    @inlinable public var startIndex: Int {
        self.index.values.startIndex
    }

    @inlinable public var endIndex: Int {
        self.index.values.endIndex
    }

    @inlinable public func index(after i: Int) -> Int {
        self.index.values.index(after: i)
    }

    @inlinable public subscript(position: Int) -> Object<ElementContext> {
        _read { yield self.index.values[position] }
    }
}
extension RuntimeContextTable where ElementContext: ~Copyable {
    @inlinable public subscript(_i position: Int) -> ElementContext {
        _read   { yield  self.index.values[position].context }
        _modify { yield &self.index.values[position].context }
    }
}
extension RuntimeContextTable where ElementContext: ~Copyable {
    @inlinable public subscript(id: ElementContext.State.ID) -> Object<ElementContext>? {
        _read { yield self.index[id] }
    }

    @inlinable mutating func append(_ element: consuming ElementContext) -> Int {
        let id: ElementContext.State.ID = element.state.id
        guard case (nil, let index): (Object<ElementContext>?, Int) = self.index.updateValue(
            .init(context: element),
            forKey: id,
            insertingAt: self.index.values.endIndex
        ) else {
            fatalError("element with id \(id) already exists!")
        }

        return index
    }
}
