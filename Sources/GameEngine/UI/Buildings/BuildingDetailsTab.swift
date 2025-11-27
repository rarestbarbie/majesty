import GameUI
import JavaScriptInterop
import JavaScriptKit

@frozen public enum BuildingDetailsTab: JSString, LoadableFromJSValue, ConvertibleToJSValue {
    case Inventory
    case Ownership
}
extension BuildingDetailsTab: InventoryTab {}
extension BuildingDetailsTab: OwnershipTab {
    typealias State = Building
    static var tooltipShares: TooltipType { .BuildingOwnershipSecurities }
}
