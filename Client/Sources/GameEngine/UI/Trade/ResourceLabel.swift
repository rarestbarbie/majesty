import GameIDs

struct ResourceLabel: Identifiable {
    let id: Resource
    let name: String
    let icon: Character
}
extension ResourceLabel {
    var nameWithIcon: String { "\(self.icon) \(self.name)" }
}
