import Bijection
import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension LocalMarket.PriceFloorType: RawRepresentable {
    @Bijection(label: "rawValue") @inlinable public var rawValue: Unicode.Scalar {
        switch self {
        case .minimumWage: "W"
        }
    }
}
extension LocalMarket.PriceFloorType: ConvertibleToJSValue, LoadableFromJSValue {}
