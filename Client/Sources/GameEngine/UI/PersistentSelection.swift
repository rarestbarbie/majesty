struct PersistentSelection<Filter, DetailsTab> where Filter: PersistentSelectionFilter {
    private var details: DetailsTab
    private var cursors: [Filter: Filter.Selection]
    private var cursor: Filter.Selection?
    private(set) var filter: Filter?

    init(details: DetailsTab) {
        self.details = details
        self.cursors = [:]
        self.cursor = nil
        self.filter = nil
    }
}
extension PersistentSelection {
    /// Sets the currently selected item and records it for stickiness.
    mutating func select(_ selected: Filter.Selection?, details: DetailsTab?) {
        self.cursor = selected
        if  let selected: Filter.Selection,
            let filter: Filter = self.filter {
            self.cursors[filter] = selected
        }
        if  let details: DetailsTab {
            self.details = details
        }
    }

    /// Changes the active filter.
    mutating func filter(_ filter: Filter) {
        self.filter = filter

        guard
        let current: Filter.Selection = self.cursor else {
            self.cursor = self.cursors[filter]
            return
        }

        if  filter ~= current {
            self.cursors[filter] = current
        } else {
            self.cursor = self.cursors[filter]
        }
    }
}
extension PersistentSelection {
    mutating func rebuild<Source, Entry, Details>(
        filtering objects: some Collection<Source>,
        entries: inout [Entry],
        details: inout Details?,
        default: @autoclosure () -> Filter,
        _ entry: (Source) -> Entry?,
        update: (inout Details, Entry, Source) -> Void
    ) where Details: PersistentReportDetails<Filter.Selection, DetailsTab>,
        Source: Identifiable<Filter.Selection> {
        let filter: Filter

        if  let current: Filter = self.filter {
            filter = current
        } else {
            filter = `default`()
            self.filter(filter)
        }

        if  let selected: Filter.Selection = self.cursor {
            if case selected? = details?.id {
                // no change
            } else {
                details = .init(id: selected, open: self.details)
            }
        } else {
            // will be populated below
            details = nil
        }

        entries.removeAll(keepingCapacity: true)

        for object: Source in objects where filter ~= object.id {
            guard
            let entry: Entry = entry(object) else {
                continue
            }

            entries.append(entry)

            if  var state: Details = consume details {
                if  state.id == object.id {
                    state.open = self.details
                    update(&state, entry, object)
                }
                details = state
            } else {
                var state: Details = .init(id: object.id, open: self.details)
                update(&state, entry, object)
                details = state
            }
        }
    }
}
