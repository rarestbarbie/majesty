import JavaScriptKit

protocol InventoryTab: ConvertibleToJSValue {
    static var Inventory: Self { get }
}
