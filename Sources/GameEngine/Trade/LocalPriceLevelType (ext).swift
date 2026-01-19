import Bijection
import GameEconomy
import JavaScriptInterop

extension LocalPriceLevelType: RawRepresentable {
    @Bijection(label: "rawValue") @inlinable public var rawValue: Unicode.Scalar {
        switch self {
        case .minimumWage: "W"
        }
    }
}
extension LocalPriceLevelType: ConvertibleToJSValue, LoadableFromJSValue {}
