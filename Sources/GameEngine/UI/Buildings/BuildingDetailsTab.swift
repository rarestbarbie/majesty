import Bijection
import GameUI
import JavaScriptInterop

@frozen public enum BuildingDetailsTab {
    case Inventory
    case Ownership
}
extension BuildingDetailsTab: CustomStringConvertible, LosslessStringConvertible {
    @Bijection @inlinable public var description: String {
        switch self {
        case .Inventory: "Inventory"
        case .Ownership: "Ownership"
        }
    }
}
extension BuildingDetailsTab: LoadableFromJSString, ConvertibleToJSString {}
extension BuildingDetailsTab: InventoryTab {}
extension BuildingDetailsTab: OwnershipTab {
    typealias State = Building
    static var tooltipShares: TooltipType { .BuildingOwnershipSecurities }
}
