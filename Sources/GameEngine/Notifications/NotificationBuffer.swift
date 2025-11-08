import GameIDs
import OrderedCollections

struct NotificationBuffer {
    private let id: CountryID
    private var list: OrderedDictionary<Int64, Notification>
    private var next: Int64
}
extension NotificationBuffer {
    init(id: CountryID) {
        self.init(id: id, list: [:], next: 1)
    }
}
extension NotificationBuffer {
    private static let history: Int = 100
}
extension NotificationBuffer {
    mutating func trim() {
        if  self.list.count >= Self.history {
            self.list.removeFirst(self.list.count - Self.history)
        }
    }

    subscript(date: GameDate) -> String? {
        get { nil }
        set(value) {
            guard let text: String = value, !text.isEmpty else {
                return
            }

            let notification: Notification = .init(id: self.next, date: date, text: text)

            print(notification)

            self.list[self.next] = notification
            self.next += 1
        }
    }
}
