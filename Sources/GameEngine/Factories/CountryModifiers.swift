import ColorText
import D
import GameConditions
import GameIDs
import GameRules
import GameUI

struct CountryModifiers {
    private(set) var factoryProductivity: [FactoryType: Stack<Int64>]
    private(set) var miningEfficiency: [MineType: Stack<Decimal>]
    private(set) var miningWidth: [MineType: Stack<Decimal>]

    init() {
        self.factoryProductivity = [:]
        self.miningEfficiency = [:]
        self.miningWidth = [:]
    }
}
extension CountryModifiers {
    mutating func update(from technologies: [Technology], rules: GameRules) {
        for id: Technology in technologies {
            guard
            let technology: TechnologyMetadata = rules.technologies[id] else {
                continue
            }
            self.update(from: technology, rules: rules)
        }
    }
    private mutating func update(from technology: TechnologyMetadata, rules: GameRules) {
        for effect: Effect in technology.effects {
            let technology: EffectProvenance = .technology(technology)
            switch effect {
            case .factoryProductivity(let value, nil):
                for type: FactoryType in rules.factories.keys {
                    self.factoryProductivity[type, default: .zero].stack(
                        with: value,
                        from: technology
                    )
                }
            case .factoryProductivity(let value, let type?):
                self.factoryProductivity[type, default: .zero].stack(
                    with: value,
                    from: technology
                )

            case .miningEfficiency(let exact, nil):
                for type: MineType in rules.mines.keys {
                    self.miningEfficiency[type, default: .zero].stack(
                        with: exact.value,
                        from: technology
                    )
                }
            case .miningEfficiency(let exact, let type?):
                self.miningEfficiency[type, default: .zero].stack(
                    with: exact.value,
                    from: technology
                )
            }
        }
    }
}
