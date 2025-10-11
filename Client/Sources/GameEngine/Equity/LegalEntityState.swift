import GameIDs

protocol LegalEntityState<Dimensions>: Turnable, Identifiable
    where Dimensions: LegalEntityMetrics, Self.ID: LegalEntityIdentifier {
    var equity: Equity<LEI> { get }
}
