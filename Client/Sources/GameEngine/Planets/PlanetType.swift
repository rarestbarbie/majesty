import JavaScriptKit
import JavaScriptInterop

@frozen public enum PlanetType: String, ConvertibleToJSValue, LoadableFromJSValue {
    case planet = "P"
    case moon = "M"
    case star = "S"
}
