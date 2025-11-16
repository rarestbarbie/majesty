import JavaScriptKit
import JavaScriptInterop

struct TableColumnMetadata<Stop>: Identifiable where Stop: ConvertibleToJSValue {
    let id: Int32
    let name: String
    var next: Stop?
    var previous: Stop?

    init(
        id: Int32,
        name: String,
        next: Stop? = nil,
        previous: Stop? = nil
    ) {
        self.id = id
        self.name = name
        self.next = next
        self.previous = previous
    }
}
extension TableColumnMetadata {
    mutating func updateStops<Entry, Key>(
        columnSelected: Int32?,
        from rows: [Entry],
        on stop: (Entry) -> Key,
        as union: (Key) -> Stop
    ) where Key: Comparable {
        update:
        if case self.id? = columnSelected {
            guard
            let first: Entry = rows.first,
            let last: Entry = rows.last else {
                break update
            }

            let skip: Key = stop(first)
            for row: Entry in rows.dropFirst() {
                let current: Key = stop(row)
                if  current != skip {
                    self.previous = union(stop(last))
                    self.next = union(current)
                    return
                }
            }
        } else {
            var highest: Key? = nil
            var lowest: Key? = nil
            for row: Entry in rows {
                let current: Key = stop(row)
                highest = highest.map { max($0, current) } ?? current
                lowest = lowest.map { min($0, current) } ?? current
            }
            if  let highest: Key,
                let lowest: Key {
                self.previous = union(highest)
                self.next = union(lowest)
                return
            }
        }

        self.previous = nil
        self.next = nil
    }
}
extension TableColumnMetadata {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case next
        case previous
    }
}
extension TableColumnMetadata: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.next] = self.next
        js[.previous] = self.previous
    }
}
