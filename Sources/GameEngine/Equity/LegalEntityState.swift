import Fraction
import GameIDs

protocol LegalEntityState<Dimensions>: Turnable, Identifiable
    where Dimensions: LegalEntityMetrics, Self.ID: LegalEntityIdentifier {
    var inventory: Inventory { get }
    var equity: Equity<LEI> { get }
    var tile: Address { get }
}
