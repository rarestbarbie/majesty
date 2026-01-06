import JavaScriptInterop
import JavaScriptKit

@frozen public enum PlanetMapLayer: JSString, LoadableFromJSValue, ConvertibleToJSValue {
    case Terrain
    case Population
    case AverageMilitancy
    case AverageConsciousness
}
