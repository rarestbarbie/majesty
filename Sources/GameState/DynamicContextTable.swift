import GameIDs
import OrderedCollections

@frozen public struct DynamicContextTable<ElementContext>
    where ElementContext: RuntimeContext & ~Copyable, ElementContext.State: Sectionable & Deletable {

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
extension DynamicContextTable where ElementContext: ~Copyable {
    @inlinable public init(
        states: [ElementContext.State],
        metadata: (ElementContext.State) -> ElementContext.Metadata?
    ) throws {
        let contexts: RuntimeContextTable<ElementContext> = try .init(
            states: states,
            metadata: metadata
        )
        let indices: [ElementContext.State.Section: Int] = contexts.indices.reduce(into: [:]) {
            $0[contexts[$1].context.state.section] = $1
        }
        let highest: ElementContext.State.ID = contexts.reduce(0) {
            Swift.max($0, $1.context.state.id)
        }
        self.init(contexts: contexts, indices: indices, highest: highest)
    }
}
extension DynamicContextTable where ElementContext: ~Copyable {
    @inlinable public var state: RuntimeStateTable<ElementContext> {
        .init(index: self.contexts.index)
    }
    @inlinable public var keys: OrderedSet<ElementContext.State.ID> { self.contexts.index.keys }

    @inlinable public mutating func turn(by turn: (inout ElementContext) -> Void) {
        for i: Int in self.contexts.index.values.indices {
            turn(&self.contexts.index.values[i].context)
        }
    }
}
extension DynamicContextTable: Collection where ElementContext: ~Copyable {
    @inlinable public var startIndex: Int {
        self.contexts.index.values.startIndex
    }

    @inlinable public var endIndex: Int {
        self.contexts.index.values.endIndex
    }

    @inlinable public func index(after i: Int) -> Int {
        self.contexts.index.values.index(after: i)
    }

    @inlinable public subscript(position: Int) -> Object<ElementContext> {
        _read { yield self.contexts.index.values[position] }
    }
}
extension DynamicContextTable where ElementContext: ~Copyable {
    @inlinable public subscript(_i position: Int) -> ElementContext {
        _read   { yield  self.contexts.index.values[position].context }
        _modify { yield &self.contexts.index.values[position].context }
    }
}
extension DynamicContextTable where ElementContext: ~Copyable {
    @inlinable public mutating func lint() {
        let rebuild: Bool = self.contexts.index.update { !$0.context.state.dead }
        if  rebuild {
            self.indices = self.contexts.indices.reduce(into: [:]) {
                $0[self.contexts[$1].context.state.section] = $1
            }
        }
    }

    @inlinable public subscript(id: ElementContext.State.ID) -> Object<ElementContext>? {
        _read { yield self.contexts.index[id] }
    }

    @inlinable public subscript(modifying id: ElementContext.State.ID) -> ElementContext {
        _read   {
            guard let object: Object<ElementContext> = self.contexts.index[id] else {
                fatalError("no element with id = \(id) exists!")
            }
            yield object.context
        }
        _modify {
            guard let object: Object<ElementContext> = self.contexts.index[id] else {
                fatalError("no element with id = \(id) exists!")
            }
            yield &object.context
        }
    }

    @inlinable public subscript<T>(
        section: ElementContext.State.Section,
        create create: (ElementContext.State) -> ElementContext.Metadata?,
        update update: (ElementContext.Metadata, inout ElementContext.State) throws -> T,
    ) -> T {
        mutating get throws {
            let result: T
            var new: ElementContext

            if  let index: Int = self.indices[section] {
                let object: Object<ElementContext> = self.contexts[index]
                return try update(object.context.type, &object.context.state)
            } else {
                /// Important: `incremented`, not `increment`
                let state: ElementContext.State = .init(
                    id: self.highest.incremented(),
                    section: section
                )
                guard
                let type: ElementContext.Metadata = create(state) else {
                    throw RuntimeMetadataError<ElementContext.State.ID>.missing(state.id)
                }
                new = .init(type: type, state: state)
                result = try update(type, &new.state)
            }

            self.highest = new.state.id
            let index: Int = self.contexts.append(new)
            self.indices[section] = index

            return result
        }
    }
}
