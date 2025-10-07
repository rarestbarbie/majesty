import GameState

protocol LegalEntityState<Dimensions>: CashAccountHolder, Turnable, Identifiable
    where Dimensions: LegalEntityMetrics, Self.ID: LegalEntityIdentifier {
    var equity: Equity<LEI> { get }
}
