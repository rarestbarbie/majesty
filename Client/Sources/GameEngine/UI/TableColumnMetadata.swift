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
    mutating func update<Entry, Key>(from rows: [Entry], on stop: (Entry) -> Key, as union: (Key) -> Stop) where Key: Equatable {
        if  let first: Entry = rows.first,
            let last: Entry = rows.last {
            let skip: Key = stop(first)
            for row: Entry in rows.dropFirst() {
                let current: Key = stop(row)
                if  current != skip {
                    self.previous = union(stop(last))
                    self.next = union(current)
                    return
                }
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
