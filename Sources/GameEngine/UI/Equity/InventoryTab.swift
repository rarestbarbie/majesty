import JavaScriptInterop

protocol InventoryTab: ConvertibleToJSValue, Sendable {
    static var Inventory: Self { get }
}
