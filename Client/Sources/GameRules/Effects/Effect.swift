@frozen public enum Effect: Equatable, Hashable, Sendable {
    case factoryProductivity(EffectsTable<FactoryType, Int64>)
}
