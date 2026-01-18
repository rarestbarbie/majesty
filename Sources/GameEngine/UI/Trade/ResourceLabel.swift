import Color
import GameIDs

struct ResourceLabel: Equatable, Identifiable {
    let id: Resource
    let icon: Character
    let title: String
    let color: Color
}
extension ResourceLabel {
    var nameWithIcon: String { "\(self.icon) \(self.title)" }
}
