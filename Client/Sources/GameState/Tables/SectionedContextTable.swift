@frozen public struct SectionedContextTable<ElementContext>
    where ElementContext: RuntimeContext, ElementContext.State: Sectionable {

    public var table: RuntimeContextTable<ElementContext>
    @usableFromInline var indices: [ElementContext.State.Section: Int]
    @usableFromInline var highest: ElementContext.State.ID

    @inlinable init(
        table: RuntimeContextTable<ElementContext>,
        indices: [ElementContext.State.Section: Int],
        highest: ElementContext.State.ID
    ) {
        self.table = table
        self.indices = indices
        self.highest = highest
    }
}
extension SectionedContextTable {
    @inlinable public init(
        states: [ElementContext.State],
        metadata: (ElementContext.State) -> ElementContext.Metadata?
    ) throws {
        let table: RuntimeContextTable<ElementContext> = try .init(
            states: states,
            metadata: metadata
        )
        let indices: [ElementContext.State.Section: Int] = table.indices.reduce(into: [:]) {
            $0[table[$1].state.section] = $1
        }
        let highest: ElementContext.State.ID = table.reduce(0) { max($0, $1.state.id) }
        self.init(table: table, indices: indices, highest: highest)
    }
}
extension SectionedContextTable {
    @inlinable public mutating func lint(
        where remove: (ElementContext.State) -> Bool
    ) {
        fatalError("unimplemented, requires index rebuilding")
    }

    @inlinable public mutating func with<T>(
        section: ElementContext.State.Section,
        create: (ElementContext.State) -> ElementContext.Metadata?,
        update: (inout ElementContext.State) throws -> T,
    ) throws -> T {
        var new: ElementContext

        if let index: Int = self.indices[section] {
            return try update(&self.table[index].state)
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
        let index: Int = self.table.append(new)

        self.highest = new.state.id
        self.indices[section] = index

        return result
    }
}
