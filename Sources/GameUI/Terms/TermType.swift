internal import Bijection
import JavaScriptKit
import JavaScriptInterop

@frozen public enum TermType: Equatable, Hashable {
    case shares
    case stockPrice
    case stockAttraction
}
extension TermType: RawRepresentable {
    @Bijection(label: "rawValue") @inlinable public var rawValue: String {
        switch self {
        case .shares: "eN"
        case .stockPrice: "eP"
        case .stockAttraction: "eA"
        }
    }
}
extension TermType: ConvertibleToJSValue, LoadableFromJSValue {}

