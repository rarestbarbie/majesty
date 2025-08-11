import GameEngine
import JavaScriptKit
import JavaScriptInterop
import VectorCharts
import VectorCharts_JavaScript

struct FactoryOwnership {
    var country: PieChart<GameID<Country>, PieChartLabel>?
    var culture: PieChart<String, PieChartLabel>?

    init() {
        self.country = nil
        self.culture = nil
    }
}
extension FactoryOwnership {
    mutating func update(from factory: FactoryContext, in context: GameContext) {
        let (country, culture): (
            country: [GameID<Country>: (share: Int64, PieChartLabel)],
            culture: [String: (share: Int64, PieChartLabel)]
        ) = factory.equity.owners.reduce(
            into: ([:], [:])
        ) {
            guard let pop: Pop = context.state.pops[$1.id] else {
                return
            }
            if  let country: GameID<Country> = context.planets[pop.home.planet]?.occupied,
                let country: Country = context.state.countries[country] {
                let label: PieChartLabel = .init(color: country.color, name: country.name)
                $0.country[country.id, default: (0, label)].share += $1.count
            }
            if  let culture: Culture = context.state.cultures[pop.nat] {
                let label: PieChartLabel = .init(color: culture.color, name: culture.id)
                $0.culture[culture.id, default: (0, label)].share += $1.count
            }
        }

        self.country = .init(
            values: country.sorted { $0.key < $1.key }
        )
        self.culture = .init(
            values: culture.sorted { $0.key < $1.key }
        )
    }
}
extension FactoryOwnership: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case country
        case culture
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = FactoryDetailsTab.Ownership
        js[.country] = self.country
        js[.culture] = self.culture
    }
}
