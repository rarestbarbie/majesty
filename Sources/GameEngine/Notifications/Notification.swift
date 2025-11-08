import GameIDs

struct Notification {
    let id: Int64
    let date: GameDate
    let text: String
}
extension Notification: CustomStringConvertible {
    var description: String {
        "[\(self.id)]: \(self.text) (\(self.date[.phrasal_US]))"
    }
}
