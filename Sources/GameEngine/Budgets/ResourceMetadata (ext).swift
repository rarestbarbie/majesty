import GameRules

extension ResourceMetadata {
    var label: PieChartLabel {
        .init(color: self.color, name: self.title)
    }
}
