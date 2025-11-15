import GameRules

enum EffectProvenance {
    case technology(TechnologyMetadata)
}
extension EffectProvenance {
    var name: String {
        switch self {
        case .technology(let self): self.title
        }
    }
}
