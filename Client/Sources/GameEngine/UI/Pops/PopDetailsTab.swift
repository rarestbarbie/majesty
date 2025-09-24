import JavaScriptInterop
import JavaScriptKit

@frozen public enum PopDetailsTab: JSString, LoadableFromJSValue, ConvertibleToJSValue {
    case Inventory
    case Ownership
}
extension PopDetailsTab: InventoryTab {}
extension PopDetailsTab: OwnershipTab {}
