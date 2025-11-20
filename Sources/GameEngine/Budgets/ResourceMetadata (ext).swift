import GameRules

extension ResourceMetadata {
    var label: ResourceLabel {
        .init(id: self.id, icon: self.emoji, title: self.title, color: self.color)
    }
}
