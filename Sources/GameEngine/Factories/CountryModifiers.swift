import ColorText
import D
import Fraction
import GameEconomy
import GameConditions
import GameIDs
import GameRules
import GameUI

struct CountryModifiers {
    private(set) var factoryProductivity: [FactoryType: Stack<Int64>]
    private(set) var miningEfficiency: [MineType: Stack<Decimal>]
    private(set) var miningWidth: [MineType: Stack<Decimal>]

    private(set) var livestockBreedingEfficiency: Stack<Decimal>
    private(set) var livestockCullingEfficiency: Stack<Decimal>

    let localMarkets: [Resource: LocalMarket.Policy]

    private init(localMarkets: [Resource: LocalMarket.Policy]) {
        self.factoryProductivity = [:]
        self.miningEfficiency = [:]
        self.miningWidth = [:]

        self.livestockBreedingEfficiency = .zero
        self.livestockCullingEfficiency = .zero

        self.localMarkets = localMarkets
    }
}
extension CountryModifiers {
    static func compute(for country: Country, rules: GameMetadata) -> Self {
        var localMarkets: [Resource: LocalMarket.Policy] = [:]
        for resource: ResourceMetadata in rules.resources.local {
            let min: LocalPriceLevel?

            if let hours: Int64 = resource.hours {
                min = .init(
                    price: LocalPrice.init(country.minwage %/ hours),
                    label: .minimumWage
                )
            } else {
                min = nil
            }

            localMarkets[resource.id] = .init(
                storage: resource.storable ? 16 : nil,
                limit: (min: min, max: nil)
            )
        }

        var modifiers: CountryModifiers = .init(localMarkets: localMarkets)
        ;   modifiers.update(from: country.researched, rules: rules)
        return modifiers
    }

    private mutating func update(from technologies: [Technology], rules: GameMetadata) {
        for id: Technology in technologies {
            guard
            let technology: TechnologyMetadata = rules.technologies[id] else {
                continue
            }
            self.update(from: technology, rules: rules)
        }
    }
    private mutating func update(from technology: TechnologyMetadata, rules: GameMetadata) {
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

            case .livestockBreedingEfficiency(let exact):
                self.livestockBreedingEfficiency.stack(
                    with: exact.value,
                    from: technology
                )
            case .livestockCullingEfficiency(let exact):
                self.livestockCullingEfficiency.stack(
                    with: exact.value,
                    from: technology
                )
            }
        }
    }
}
