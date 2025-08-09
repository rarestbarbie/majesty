import GameRules

struct FactoryModifiers {
    var productivity: EffectsMatrix<FactoryType>

    init() {
        self.productivity = .init()
    }
}
