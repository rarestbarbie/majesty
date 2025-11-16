import GameEconomy
import GameIDs
import JavaScriptInterop
import JavaScriptKit

struct EffectsDescription {
    let factoryProductivityAll: Int64?
    let factoryProductivity: SymbolTable<Int64>?

    let miningEfficiencyAll: Exact?
    let miningEfficiency: SymbolTable<Exact>?
}
extension EffectsDescription {
    func resolved(with symbols: GameSaveSymbols) throws -> [Effect] {
        var effects: [Effect] = []

        if  let value: Int64 = self.factoryProductivityAll {
            effects.append(.factoryProductivity(value, nil))
        }
        if  let productivity: SymbolTable<Int64> = self.factoryProductivity {
            for effect: Quantity<FactoryType> in try productivity.quantities(
                    keys: symbols.factories
                ) {
                effects.append(.factoryProductivity(effect.amount, effect.unit))
            }
        }

        if  let value: Exact = self.miningEfficiencyAll {
            effects.append(.miningEfficiency(value, nil))
        }
        if  let efficiency: SymbolTable<Exact> = self.miningEfficiency {
            for (predicate, amount): (MineType, Exact) in try efficiency.quantities(
                    keys: symbols.mines
                ) {
                effects.append(.miningEfficiency(amount, predicate))
            }
        }

        return effects
    }
}
extension EffectsDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case factory_productivity_all
        case factory_productivity
        case mining_efficiency_all
        case mining_efficiency
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            factoryProductivityAll: try js[.factory_productivity_all]?.decode(),
            factoryProductivity: try js[.factory_productivity]?.decode(),
            miningEfficiencyAll: try js[.mining_efficiency_all]?.decode(),
            miningEfficiency: try js[.mining_efficiency]?.decode()
        )
    }
}
