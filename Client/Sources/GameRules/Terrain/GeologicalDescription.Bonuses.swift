import JavaScriptInterop
import JavaScriptKit
import OrderedCollections

extension GeologicalDescription {
    struct Bonuses {
        var weightNone: Int64
        var weights: OrderedDictionary<Symbol, GeologicalSpawnWeight>
    }
}
extension GeologicalDescription.Bonuses: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self = try js.values {
            .init(weightNone: 0, weights: .init(minimumCapacity: $0))
        } combine: {
            let weight: GeologicalSpawnWeight = $2
            switch $1 {
            case .underscore:
                $0.weightNone = weight.chance
            case .resource(let symbol):
                $0.weights[symbol] = weight
            }
        }
    }
}
