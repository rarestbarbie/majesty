import GameEconomy
import GameIDs

struct LocalMarketModifiers {
    var templates: [Resource: LocalMarket.Shape]

    @inlinable public init() {
        self.templates = [:]
    }
}
extension LocalMarketModifiers {
    subscript(resource: Resource) -> LocalMarket.Shape {
        self.templates[resource] ?? .default
    }
}
