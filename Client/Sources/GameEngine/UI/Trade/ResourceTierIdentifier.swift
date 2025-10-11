import JavaScriptKit
import JavaScriptInterop

@frozen public enum ResourceTierIdentifier: Unicode.Scalar,
    LoadableFromJSValue,
    ConvertibleToJSValue {
    /// Pop, life need.
    case l = "l"
    /// Pop, everyday need.
    case e = "e"
    /// Pop, luxury need.
    case x = "x"

    /// Factory, input.
    case i = "i"
    /// Factory, expansion progress.
    case v = "v"

    case o = "o"
}
