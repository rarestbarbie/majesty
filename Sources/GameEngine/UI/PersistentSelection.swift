import OrderedCollections

@dynamicMemberLookup struct PersistentSelection<Filter, DetailsFocus>
    where Filter: PersistentSelectionFilter {
    private var details: DetailsFocus
    private var cursors: [Filter: Filter.Subject.ID]
    private var cursor: Filter.Subject.ID?
    private(set) var filter: Filter?

    init(defaultFocus: DetailsFocus) {
        self.details = defaultFocus
        self.cursors = [:]
        self.cursor = nil
        self.filter = nil
    }
}
extension PersistentSelection: Sendable
    where DetailsFocus: Sendable, Filter.Subject.ID: Sendable, Filter: Sendable {}
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
    mutating func select(_ selected: Filter.Subject.ID?, filter: Filter?) {
        if  let selected: Filter.Subject.ID,
            let filter: Filter = self.filter {
            self.cursor = selected
            self.cursors[filter] = selected
        }
        if  let filter: Filter {
            self.filter(filter)
        }
    }

    /// Changes the active filter.
    private mutating func filter(_ filter: Filter) {
        self.filter = filter
        self.cursor = self.cursors[filter] ?? self.cursor
    }
}
extension PersistentSelection {
    mutating func rebuild<Entry, Details>(
        filtering objects: some RandomAccessMapping<Filter.Subject.ID, Filter.Subject>,
        entries: inout [Entry],
        details: inout Details?,
        default: @autoclosure () -> Filter,
        sort ascending: (_ a: Entry, _ b: Entry) -> Bool,
        _ entry: (Filter.Subject) -> Entry?,
        update: (inout Details, Entry, Filter.Subject) -> Void
    ) where Details: PersistentReportDetails<Filter.Subject.ID, DetailsFocus>,
        Entry: Identifiable<Filter.Subject.ID> {
        let filter: Filter

        if  let current: Filter = self.filter {
            filter = current
        } else {
            filter = `default`()
            self.filter(filter)
        }

        entries.removeAll(keepingCapacity: true)

        var selected: Entry? = nil
        for object: Filter.Subject in objects.values where filter ~= object {
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
