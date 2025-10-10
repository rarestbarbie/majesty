import GameIDs
import OrderedCollections

struct Notifications {
    private(set) var date: GameDate
    private var buffers: OrderedDictionary<CountryID, NotificationBuffer>
}
extension Notifications {
    init(date: GameDate) {
        self.date = date
        self.buffers = [:]
    }

    private(set) subscript(yielding id: CountryID) -> NotificationBuffer {
        _read   { yield  self.buffers[id, default: .init(id: id)] }
        _modify { yield &self.buffers[id, default: .init(id: id)] }
    }

    subscript(subscribers: [CountryID]) -> String? {
        get { nil }
        set (value) {
            guard let value: String else {
                return
            }
            for id: CountryID in subscribers {
                self[yielding: id][self.date] = value
            }
        }
    }

    subscript(subscribers: CountryID...) -> String? {
        get { nil }
        set (value) {
            self[subscribers] = value
        }
    }
}
extension Notifications {
    mutating func turn() {
        self.date.increment()
        for i: Int in self.buffers.values.indices {
            self.buffers.values[i].trim()
        }
    }
}
