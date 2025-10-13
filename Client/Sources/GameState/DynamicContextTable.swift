import GameIDs
import OrderedCollections

@frozen public struct DynamicContextTable<ElementContext>
    where ElementContext: RuntimeContext, ElementContext.State: Sectionable & Deletable {

    @usableFromInline var contexts: RuntimeContextTable<ElementContext>
    @usableFromInline var indices: [ElementContext.State.Section: Int]
    /// Note, we need to serialize this, as it is not derivable from the indices. For example,
    /// items with high indices may die, and we need to make sure those IDs are not reused.
    @usableFromInline var highest: ElementContext.State.ID

    @inlinable init(
        contexts: RuntimeContextTable<ElementContext>,
        indices: [ElementContext.State.Section: Int],
        highest: ElementContext.State.ID
    ) {
        self.contexts = contexts
        self.indices = indices
        self.highest = highest
    }
}
extension DynamicContextTable {
    @inlinable public init(
        states: [ElementContext.State],
        metadata: (ElementContext.State) -> ElementContext.Metadata?
    ) throws {
        let contexts: RuntimeContextTable<ElementContext> = try .init(
            states: states,
            metadata: metadata
        )
        let indices: [ElementContext.State.Section: Int] = contexts.indices.reduce(into: [:]) {
            $0[contexts[$1].state.section] = $1
        }
        let highest: ElementContext.State.ID = contexts.reduce(0) { Swift.max($0, $1.state.id) }
        self.init(contexts: contexts, indices: indices, highest: highest)
    }
}
extension DynamicContextTable {
    @inlinable public var state: RuntimeStateTable<ElementContext> {
        .init(index: self.contexts.index)
    }
    @inlinable public var keys: OrderedSet<ElementContext.State.ID> { self.contexts.index.keys }

    @inlinable public mutating func turn(by turn: (inout ElementContext) -> Void) {
        for i: Int in self.contexts.index.values.indices {
            turn(&self.contexts.index.values[i])
        }
    }
}
extension DynamicContextTable: Collection {
    @inlinable public var startIndex: Int {
        self.contexts.index.values.startIndex
    }

    @inlinable public var endIndex: Int {
        self.contexts.index.values.endIndex
    }

    @inlinable public func index(after i: Int) -> Int {
        self.contexts.index.values.index(after: i)
    }

    @inlinable public subscript(position: Int) -> ElementContext {
        get { self.contexts.index.values[position] }
        set { self.contexts.index.values[position] = newValue }
        _modify { yield &self.contexts.index.values[position] }
    }
}
extension DynamicContextTable {
    @inlinable public mutating func lint() {
        let rebuild: Bool = self.contexts.index.update { !$0.state.dead }
        if  rebuild {
            self.indices = self.contexts.indices.reduce(into: [:]) {
                $0[self.contexts[$1].state.section] = $1
            }
        }
    }

    @inlinable public subscript(id: ElementContext.State.ID) -> ElementContext? {
        self.contexts.index[id]
    }

    @inlinable public subscript(modifying id: ElementContext.State.ID) -> ElementContext {
        _read   {
            guard let i: Int = self.contexts.index.index(forKey: id) else {
                fatalError("no element with id = \(id) exists!")
            }
            yield self.contexts.index.values[i]
        }
        _modify {
            guard let i: Int = self.contexts.index.index(forKey: id) else {
                fatalError("no element with id = \(id) exists!")
            }
            yield &self.contexts.index.values[i]
        }
    }

    @inlinable public subscript<T>(
        section: ElementContext.State.Section,
        create create: (ElementContext.State) -> ElementContext.Metadata?,
        update update: (inout ElementContext.State) throws -> T,
    ) -> T {
        mutating get throws {
            var new: ElementContext

            if let index: Int = self.indices[section] {
                return try update(&self.contexts[index].state)
            } else {
                /// Important: `incremented`, not `increment`
                let state: ElementContext.State = .init(
                    id: self.highest.incremented(),
                    section: section
                )
                if let type: ElementContext.Metadata = create(state) {
                    new = .init(type: type, state: state)
                } else {
                    throw RuntimeMetadataError<Void>.missing(())
                }
            }

            let result: T = try update(&new.state)
            let index: Int = self.contexts.append(new)

            self.highest = new.state.id
            self.indices[section] = index

            return result
        }
    }
}
