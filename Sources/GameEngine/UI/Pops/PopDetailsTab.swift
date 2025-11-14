import GameUI
import JavaScriptInterop
import JavaScriptKit

@frozen public enum PopDetailsTab: JSString, LoadableFromJSValue, ConvertibleToJSValue {
    case Inventory
    case Ownership
}
extension PopDetailsTab: InventoryTab {}
extension PopDetailsTab: OwnershipTab {
    typealias State = Pop
    static var tooltipShares: TooltipType { .PopOwnershipSecurities }
}
