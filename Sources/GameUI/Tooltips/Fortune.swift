import JavaScriptInterop

/// Defines the visual style for a given data point, corresponding to the TypeScript enum.
@frozen public enum Fortune: String, ConvertibleToJSValue {
    case bonus
    case malus
}
