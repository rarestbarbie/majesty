import JavaScriptInterop
import JavaScriptKit

@frozen public enum MinimapLayer: String, ConvertibleToJSValue, LoadableFromJSValue {
    case Terrain
    case Population
    case AverageMilitancy
    case AverageConsciousness
}
