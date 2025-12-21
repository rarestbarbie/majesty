import JavaScriptKit

protocol InventoryTab: ConvertibleToJSValue, Sendable {
    static var Inventory: Self { get }
}
