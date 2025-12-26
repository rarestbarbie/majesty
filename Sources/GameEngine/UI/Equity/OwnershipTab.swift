import JavaScriptKit
import GameUI

protocol OwnershipTab: ConvertibleToJSValue, Sendable {
    associatedtype State: Turnable & Identifiable where State.Dimensions: LegalEntityMetrics
    static var Ownership: Self { get }
    static var tooltipShares: TooltipType { get }
}
