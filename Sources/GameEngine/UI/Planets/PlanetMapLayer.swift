import Bijection
import JavaScriptInterop

@frozen public enum PlanetMapLayer: CaseIterable {
    case Terrain
    case Population
    case AverageMilitancy
    case AverageConsciousness
}
extension PlanetMapLayer: LoadableFromJSString, ConvertibleToJSString {}
extension PlanetMapLayer: CustomStringConvertible, LosslessStringConvertible {
    @Bijection @inlinable public var description: String {
        switch self {
        case .Terrain: "Terrain"
        case .Population: "Population"
        case .AverageMilitancy: "AverageMilitancy"
        case .AverageConsciousness: "AverageConsciousness"
        }
    }
}
