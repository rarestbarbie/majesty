import GameEconomy
import GameIDs

struct LocalMarketModifiers {
    var templates: [Resource: LocalMarket.Template]

    @inlinable public init() {
        self.templates = [:]
    }
}
extension LocalMarketModifiers {
    subscript(resource: Resource) -> LocalMarket.Template {
        self.templates[resource] ?? .default
    }
}
