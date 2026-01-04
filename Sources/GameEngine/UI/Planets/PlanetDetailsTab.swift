import JavaScriptInterop
import JavaScriptKit

/// Currently the same as ``MinimapLayer``, but kept separate for clarity and future extensions.
@frozen public enum PlanetDetailsTab: JSString, LoadableFromJSValue, ConvertibleToJSValue {
    case Terrain
    case Population
    case AverageMilitancy
    case AverageConsciousness
}
