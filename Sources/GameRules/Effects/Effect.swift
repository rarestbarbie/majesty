import GameIDs

@frozen public enum Effect: Equatable, Hashable, Sendable {
    case factoryProductivity(Int64, FactoryType?)
    case miningEfficiency(Exact, MineType?)
}
