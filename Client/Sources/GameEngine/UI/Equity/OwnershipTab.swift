import JavaScriptKit

protocol OwnershipTab: ConvertibleToJSValue {
    associatedtype State: Turnable where State.Dimensions: LegalEntityMetrics
    static var Ownership: Self { get }
}
