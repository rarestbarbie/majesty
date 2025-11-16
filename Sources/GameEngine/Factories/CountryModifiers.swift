import ColorText
import D
import GameConditions
import GameIDs
import GameRules
import GameUI

struct CountryModifiers {
    private(set) var factoryProductivity: [FactoryType: Stack<Int64>]
    private(set) var miningEfficiency: [MineType: Stack<Decimal>]

    init() {
        self.factoryProductivity = [:]
        self.miningEfficiency = [:]
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
extension CountryModifiers {
    func tooltipEfficiency(mine: MineType) -> Tooltip {
        let evaluator: ConditionBreakdown = self.computeEfficiency(mine: mine)
        return .conditions(
            .list(
                "Mining efficiency: \(em: evaluator.output[%2])",
                breakdown: evaluator
            ),
        )
    }

    private func computeEfficiency<Matrix>(
        mine: MineType,
        type: Matrix.Type = Matrix.self,
    ) -> Matrix where Matrix: ConditionMatrix<Decimal, Double> {
        .init(base: 1%) {
            for (value, effect): (
                    Decimal,
                    EffectProvenance
                ) in self.miningEfficiency[mine]?.blame ?? [] {
                $0[true] { $0 = value } = { "\(+$0[%]): \(effect.name)" }
            }
        } factors: {
            _ in
        }
    }
}
