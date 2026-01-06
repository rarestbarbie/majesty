struct LegalEntityFocus<Tab>: Sendable where Tab: Sendable {
    var tab: Tab
    var needs: ResourceTierIdentifier
}
