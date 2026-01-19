import Bijection
import GameUI
import JavaScriptInterop

@frozen public enum PopDetailsTab {
    case Inventory
    case Ownership
}
extension PopDetailsTab: CustomStringConvertible, LosslessStringConvertible {
    @Bijection @inlinable public var description: String {
        switch self {
        case .Inventory: "Inventory"
        case .Ownership: "Ownership"
        }
    }
}
extension PopDetailsTab: LoadableFromJSString, ConvertibleToJSString {}
extension PopDetailsTab: InventoryTab {}
extension PopDetailsTab: OwnershipTab {
    typealias State = Pop
    static var tooltipShares: TooltipType { .PopOwnershipSecurities }
}
