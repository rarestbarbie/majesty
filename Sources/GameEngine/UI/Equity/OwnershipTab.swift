import JavaScriptKit
import GameUI

protocol OwnershipTab: ConvertibleToJSValue {
    associatedtype State: Turnable where State.Dimensions: LegalEntityMetrics
    static var Ownership: Self { get }
    static var tooltipShares: TooltipType { get }
}
