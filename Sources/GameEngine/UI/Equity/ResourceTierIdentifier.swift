import Bijection
import JavaScriptKit
import JavaScriptInterop

@frozen public enum ResourceTierIdentifier {
    /// Pop, life need.
    case l
    /// Pop, everyday need.
    case e
    /// Pop, luxury need.
    case x
}
extension ResourceTierIdentifier: LoadableFromJSString, ConvertibleToJSString {}
extension ResourceTierIdentifier: CustomStringConvertible, LosslessStringConvertible {
    @Bijection @inlinable public var description: String {
        switch self {
        case .l: "l"
        case .e: "e"
        case .x: "x"
        }
    }
}
