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
        filtering objects: some Collection<Filter.Subject>,
        entries: inout [Entry.ID: Entry],
        details: inout Details?,
        default: @autoclosure () -> Filter,
        _ entry: (Filter.Subject) -> Entry?,
        update: (inout Details, Entry, Filter.Subject) -> Void
    ) where Details: PersistentReportDetails<Filter.Subject.ID, DetailsFocus>,
        Entry: Identifiable {
        let filter: Filter

        if  let current: Filter = self.filter {
            filter = current
        } else {
            filter = `default`()
            self.filter(filter)
        }

        // i wonder if there is a more efficient way to do this
        if  let selected: Filter.Subject.ID = self.cursor {
            if  objects.contains(where: { $0.id == selected && filter ~= $0 }) {
                // if we’ve changed filters, but the old selection is still valid, keep it
                self.cursors[filter] = selected
            } else {
                self.cursor = nil
            }
        }

        // if no active selection, `details` will be automatically switched to the first valid
        // table entry below
        if  let selected: Filter.Subject.ID = self.cursor {
            if case selected? = details?.id {
                // no change
            } else {
                details = .init(id: selected, focus: self.details)
            }
        } else {
            details = nil
        }

        entries.removeAll(keepingCapacity: true)

        for object: Filter.Subject in objects where filter ~= object {
            guard
            let entry: Entry = entry(object) else {
                continue
            }

            entries[entry.id] = entry

            if  var state: Details = consume details {
                if  state.id == object.id {
                    state.refocus(on: self.details)
                    update(&state, entry, object)
                }
                details = state
            } else {
                var state: Details = .init(id: object.id, focus: self.details)
                update(&state, entry, object)
                details = state
            }
        }
    }
    mutating func rebuild<Entry, Details>(
        filtering objects: some Collection<Filter.Subject>,
        entries: inout [Entry],
        details: inout Details?,
        default: @autoclosure () -> Filter,
        _ entry: (Filter.Subject) -> Entry?,
        update: (inout Details, Entry, Filter.Subject) -> Void
    ) where Details: PersistentReportDetails<Filter.Subject.ID, DetailsFocus> {
        let filter: Filter

        if  let current: Filter = self.filter {
            filter = current
        } else {
            filter = `default`()
            self.filter(filter)
        }

        // i wonder if there is a more efficient way to do this
        if  let selected: Filter.Subject.ID = self.cursor {
            if  objects.contains(where: { $0.id == selected && filter ~= $0 }) {
                // if we’ve changed filters, but the old selection is still valid, keep it
                self.cursors[filter] = selected
            } else {
                self.cursor = nil
            }
        }

        // if no active selection, `details` will be automatically switched to the first valid
        // table entry below
        if  let selected: Filter.Subject.ID = self.cursor {
            if case selected? = details?.id {
                // no change
            } else {
                details = .init(id: selected, focus: self.details)
            }
        } else {
            details = nil
        }

        entries.removeAll(keepingCapacity: true)

        for object: Filter.Subject in objects where filter ~= object {
            guard
            let entry: Entry = entry(object) else {
                continue
            }

            entries.append(entry)

            if  var state: Details = consume details {
                if  state.id == object.id {
                    state.refocus(on: self.details)
                    update(&state, entry, object)
                }
                details = state
            } else {
                var state: Details = .init(id: object.id, focus: self.details)
                update(&state, entry, object)
                details = state
            }
        }
    }
}
