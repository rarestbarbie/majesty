struct PersistentSelection<Filter, DetailsTab> where Filter: PersistentSelectionFilter {
    private var detailsTab: DetailsTab
    private var cursors: [Filter: Filter.Subject.ID]
    private var cursor: Filter.Subject.ID?
    private(set) var filter: Filter?

    init(defaultTab: DetailsTab) {
        self.detailsTab = defaultTab
        self.cursors = [:]
        self.cursor = nil
        self.filter = nil
    }
}
extension PersistentSelection {
    /// Sets the currently selected item and records it for stickiness.
    mutating func select(_ selected: Filter.Subject.ID?, detailsTab: DetailsTab?) {
        if  let selected: Filter.Subject.ID,
            let filter: Filter = self.filter {
            self.cursor = selected
            self.cursors[filter] = selected
        }
        if  let detailsTab: DetailsTab {
            self.detailsTab = detailsTab
        }
    }

    /// Changes the active filter.
    mutating func filter(_ filter: Filter) {
        self.filter = filter
        self.cursor = self.cursor ?? self.cursors[filter]
    }
}
extension PersistentSelection {
    mutating func rebuild<Entry, Details>(
        filtering objects: some Collection<Filter.Subject>,
        entries: inout [Entry],
        details: inout Details?,
        default: @autoclosure () -> Filter,
        _ entry: (Filter.Subject) -> Entry?,
        update: (inout Details, Entry, Filter.Subject) -> Void
    ) where Details: PersistentReportDetails<Filter.Subject.ID, DetailsTab> {
        let filter: Filter

        if  let current: Filter = self.filter {
            filter = current
        } else {
            filter = `default`()
            self.filter(filter)
        }

        // i wonder if there is a more efficient way to do this
        if  let selected: Filter.Subject.ID = self.cursor {
            if  objects.contains(where: { filter ~= $0 }) {
                // if we’ve changed filters, but the old selection is still valid, keep it
                self.cursors[filter] = selected
            } else {
                self.cursor = nil
            }
        }

        if  let selected: Filter.Subject.ID = self.cursor {

            if case selected? = details?.id {
                // no change
            } else {
                details = .init(id: selected, open: self.detailsTab)
            }
        } else {
            // will be populated below
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
                    state.open = self.detailsTab
                    update(&state, entry, object)
                }
                details = state
            } else {
                var state: Details = .init(id: object.id, open: self.detailsTab)
                update(&state, entry, object)
                details = state
            }
        }
    }
}
