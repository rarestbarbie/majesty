import OrderedCollections

/// A read-only view of ``RuntimeContextTable``, which only permits access to the state of
/// each object.
@frozen public struct RuntimeStateTable<ElementContext> where ElementContext: RuntimeContext {
    @usableFromInline let index: OrderedDictionary<ElementContext.State.ID, ElementContext>

    @inlinable init(index: OrderedDictionary<ElementContext.State.ID, ElementContext>) {
        self.index = index
    }
}
extension RuntimeStateTable: Equatable where ElementContext.State: Equatable {
    @inlinable public static func == (a: Self, b: Self) -> Bool { a.elementsEqual(b) }
}
extension RuntimeStateTable: Hashable where ElementContext.State: Hashable {
    @inlinable public func hash(into hasher: inout Hasher) {
        for state: ElementContext.State in self {
            state.hash(into: &hasher)
        }
    }
}
extension RuntimeStateTable: Collection {
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
        self.index.values[position].state
    }
}
extension RuntimeStateTable {
    @inlinable public subscript(id: ElementContext.State.ID) -> ElementContext.State? {
        self.index[id]?.state
    }
    @inlinable public subscript(id: ElementContext.State.ID) -> (state: ElementContext.State, type: ElementContext.Metadata) {
        get throws(LookupError) {
            if  let context: ElementContext = self.index[id] {
                return (context.state, context.type)
            } else {
                throw LookupError.undefined(id)
            }
        }
    }
}
