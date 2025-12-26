import OrderedCollections

/// A read-only view of ``RuntimeContextTable``, which only permits access to the state of
/// each object.
@frozen public struct RuntimeStateTable<ElementContext> where ElementContext: ~Copyable & RuntimeContext {
    @usableFromInline let index: OrderedDictionary<ElementContext.State.ID, Object<ElementContext>>

    @inlinable init(index: OrderedDictionary<ElementContext.State.ID, Object<ElementContext>>) {
        self.index = index
    }
}
extension RuntimeStateTable: Equatable where ElementContext: ~Copyable, ElementContext.State: Equatable {
    @inlinable public static func == (a: Self, b: Self) -> Bool { a.elementsEqual(b) }
}
extension RuntimeStateTable: Hashable where ElementContext: ~Copyable, ElementContext.State: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) {
        for state: ElementContext.State in self {
            state.hash(into: &hasher)
        }
    }
}
extension RuntimeStateTable: Collection where ElementContext: ~Copyable {
    @inlinable public var startIndex: Int {
        self.index.values.startIndex
    }

    @inlinable public var endIndex: Int {
        self.index.values.endIndex
    }

    @inlinable public func index(after i: Int) -> Int {
        self.index.values.index(after: i)
    }

    @inlinable public subscript(position: Int) -> ElementContext.State {
        self.index.values[position].context.state
    }
}
extension RuntimeStateTable where ElementContext: ~Copyable  {
    @inlinable public subscript(id: ElementContext.State.ID) -> ElementContext.State? {
        self.index[id]?.context.state
    }
    @inlinable public subscript(id: ElementContext.State.ID) -> (
        state: ElementContext.State,
        type: ElementContext.Metadata
    ) {
        get throws(LookupError) {
            if  let object: Object<ElementContext> = self.index[id] {
                return (object.context.state, object.context.type)
            } else {
                throw LookupError.undefined(id)
            }
        }
    }
}
