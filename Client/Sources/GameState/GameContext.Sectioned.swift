import GameEngine

extension GameContext {
    struct Sectioned<ElementContext>
        where ElementContext: RuntimeContext, ElementContext.State: Sectionable {

        var table: Table<ElementContext>
        private var indices: [ElementContext.State.Section: Int]
        private var highest: GameID<ElementContext.State>

        private init(
            table: Table<ElementContext>,
            indices: [ElementContext.State.Section: Int],
            highest: GameID<ElementContext.State>
        ) {
            self.table = table
            self.indices = indices
            self.highest = highest
        }
    }
}
extension GameContext.Sectioned {
    init(
        states: [ElementContext.State],
        metadata: (ElementContext.State) -> ElementContext.Metadata?
    ) throws {
        let table: GameContext.Table<ElementContext> = try .init(
            states: states,
            metadata: metadata
        )
        let indices: [ElementContext.State.Section: Int] = table.indices.reduce(into: [:]) {
            $0[table[$1].state.section] = $1
        }
        let highest: GameID<ElementContext.State> = table.reduce(0) { max($0, $1.state.id) }
        self.init(table: table, indices: indices, highest: highest)
    }
}
extension GameContext.Sectioned {
    mutating func with<T>(
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
