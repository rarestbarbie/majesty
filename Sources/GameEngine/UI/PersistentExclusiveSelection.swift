@dynamicMemberLookup struct PersistentExclusiveSelection<Filter, DetailsFocus>
    where Filter: PersistentExclusiveSelectionFilter {
    private(set) var details: DetailsFocus
    private(set) var filter: Filter?
    private(set) var cursors: [Filter: Filter.Subject.ID]
    private(set) var cursor: Filter.Subject.ID?

    init(defaultFocus: DetailsFocus) {
        self.details = defaultFocus
        self.cursors = [:]
        self.filter = nil
        self.cursor = nil
    }
}
extension PersistentExclusiveSelection: Sendable
    where DetailsFocus: Sendable, Filter.Subject.ID: Sendable, Filter: Sendable {}
extension PersistentExclusiveSelection {
    subscript<T>(dynamicMember keyPath: WritableKeyPath<DetailsFocus, T>) -> T? {
        get {
            self.details[keyPath: keyPath]
        }
        set(value) {
            guard let value: T = value else {
                return
            }
            self.details[keyPath: keyPath] = value
        }
    }
}
extension PersistentExclusiveSelection {
    /// Restore cursor state
    private mutating func restore() {
        if  let filter: Filter = self.filter {
            self.cursor = self.cursors[filter] ?? self.cursor
        }
    }
}
extension PersistentExclusiveSelection {
    /// Sets the currently selected item and records it for stickiness.
    mutating func select(_ selected: Filter.Subject.ID?, filter: Filter?) {
        if  let selected: Filter.Subject.ID,
            let filter: Filter = self.filter {
            self.cursor = selected
            self.cursors[filter] = selected
        }
        if  let filter: Filter {
            self.filter = filter
            self.restore()
        }
    }

    mutating func filter(default filter: () -> Filter?) {
        guard case nil = self.filter,
        let filter: Filter = filter() else {
            return
        }

        self.filter = filter
        self.restore()
    }

    mutating func update<Entry, Details>(
        objects: some RandomAccessMapping<Filter.Subject.ID, Filter.Subject>,
        entries: [Entry],
        details: inout Details?,
        update: (inout Details, Entry, Filter.Subject) -> ()
    ) where Details: PersistentReportDetails<Filter.Subject.ID, DetailsFocus>,
        Entry: Identifiable<Filter.Subject.ID> {


        var selected: Entry? = nil
        if  let cursor: Filter.Subject.ID = self.cursor {
            selected = entries.first { cursor == $0.id }
        }

        if case _? = selected,
            let filter: Filter = self.filter {
            // if we’ve changed filters, but the old selection is still valid, keep it
            self.cursors[filter] = self.cursor
        } else {
            self.cursor = nil
            selected = entries.first
        }

        guard
        let selected: Entry,
        let object: Filter.Subject = objects[selected.id] else {
            details = nil
            return
        }

        if  var state: Details = consume details,
                state.id == selected.id {
            state.refocus(on: self.details)
            update(&state, selected, object)
            details = state
        } else {
            var state: Details = .init(id: object.id, focus: self.details)
            update(&state, selected, object)
            details = state
        }
    }
}
