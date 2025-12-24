import OrderedCollections

@dynamicMemberLookup struct PersistentSelection<Filters, DetailsFocus>
    where Filters: PersistentSelectionFilter {
    private(set) var details: DetailsFocus
    private(set) var filters: Filters
    private(set) var cursors: [Filters: Filters.Subject.ID]
    private(set) var cursor: Filters.Subject.ID?

    init(defaultFocus: DetailsFocus) {
        self.details = defaultFocus
        self.cursors = [:]
        self.filters = .all
        self.cursor = nil
    }
}
extension PersistentSelection: Sendable
    where DetailsFocus: Sendable, Filters.Subject.ID: Sendable, Filters: Sendable {}
extension PersistentSelection {
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
extension PersistentSelection {
    /// Sets the currently selected item and records it for stickiness.
    mutating func select(_ selected: Filters.Subject.ID?, filter: Filters.Layer?) {
        if  let selected: Filters.Subject.ID,
            self.filters != .all {
            self.cursor = selected
            self.cursors[self.filters] = selected
        }
        if  let filter: Filters.Layer {
            self.filters += filter
            self.restore()
        }
    }

    /// Restore cursor state
    private mutating func restore() {
        self.cursor = self.cursors[self.filters] ?? self.cursor
    }
}
extension PersistentSelection {
    mutating func rebuild<Entry, Details>(
        filtering objects: some RandomAccessMapping<Filters.Subject.ID, Filters.Subject>,
        entries: inout [Entry],
        details: inout Details?,
        sort ascending: (_ a: Entry, _ b: Entry) -> Bool,
        _ entry: (Filters.Subject) -> Entry?,
        filter: (inout Filters) -> (),
        update: (inout Details, Entry, Filters.Subject) -> ()
    ) where Details: PersistentReportDetails<Filters.Subject.ID, DetailsFocus>,
        Entry: Identifiable<Filters.Subject.ID> {
        var filters: Filters = self.filters ; filter(&filters)
        if  filters != self.filters {
            self.filters = filters
            self.restore()
        }

        entries.removeAll(keepingCapacity: true)

        var selected: Entry? = nil
        for object: Filters.Subject in objects.values where self.filters ~= object {
            guard
            let entry: Entry = entry(object) else {
                continue
            }

            entries.append(entry)

            if  case nil = selected,
                case object.id? = self.cursor {
                selected = entry
            }
        }

        entries.sort(by: ascending)

        if case _? = selected {
            // if we’ve changed filters, but the old selection is still valid, keep it
            self.cursors[self.filters] = self.cursor
        } else {
            self.cursor = nil
            selected = entries.first
        }

        guard
        let selected: Entry,
        let object: Filters.Subject = objects[selected.id] else {
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
