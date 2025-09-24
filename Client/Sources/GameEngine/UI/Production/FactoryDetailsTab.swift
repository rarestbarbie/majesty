import JavaScriptInterop
import JavaScriptKit

@frozen public enum FactoryDetailsTab: JSString, LoadableFromJSValue, ConvertibleToJSValue {
    case Inventory
    case Ownership
}
extension FactoryDetailsTab: InventoryTab {}
extension FactoryDetailsTab: OwnershipTab {}
