import Bijection
import GameUI
import JavaScriptInterop
import JavaScriptKit

@frozen public enum FactoryDetailsTab {
    case Inventory
    case Ownership
}
extension FactoryDetailsTab: CustomStringConvertible, LosslessStringConvertible {
    @Bijection @inlinable public var description: String {
        switch self {
        case .Inventory: "Inventory"
        case .Ownership: "Ownership"
        }
    }
}
extension FactoryDetailsTab: LoadableFromJSString, ConvertibleToJSString {}
extension FactoryDetailsTab: InventoryTab {}
extension FactoryDetailsTab: OwnershipTab {
    typealias State = Factory
    static var tooltipShares: TooltipType { .FactoryOwnershipSecurities }
}
