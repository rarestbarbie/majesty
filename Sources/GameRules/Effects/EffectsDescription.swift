import JavaScriptInterop
import JavaScriptKit

struct EffectsDescription {
    let factoryProductivity: SymbolTable<Int64>?
}
extension EffectsDescription {
    func resolved(with symbols: GameSaveSymbols) throws -> [Effect] {
        var effects: [Effect] = []
        if let productivity: SymbolTable<Int64> = self.factoryProductivity {
            effects.append(.factoryProductivity(try productivity.effects(keys: symbols.factories, wildcard: "*")))
        }
        return effects
    }
}
extension EffectsDescription: JavaScriptDecodable {
    enum ObjectKey: JSString {
        case factory_productivity
    }

    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            factoryProductivity: try js[.factory_productivity]?.decode()
        )
    }
}
