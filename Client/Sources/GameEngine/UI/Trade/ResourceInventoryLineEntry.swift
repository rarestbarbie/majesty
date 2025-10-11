protocol ResourceInventoryLineEntry: Identifiable<ResourceInventoryLine> {
    var label: ResourceLabel { get }
    var tier: ResourceTierIdentifier { get }
}
extension ResourceInventoryLineEntry {
    var id: ResourceInventoryLine { .init(type: self.label.id, tier: self.tier) }
}
