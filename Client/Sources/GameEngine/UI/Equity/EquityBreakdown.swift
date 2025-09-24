import GameState
import JavaScriptKit
import JavaScriptInterop
import VectorCharts
import VectorCharts_JavaScript

struct EquityBreakdown {
    var country: PieChart<CountryID, PieChartLabel>?
    var culture: PieChart<String, PieChartLabel>?

    init() {
        self.country = nil
        self.culture = nil
    }
}
extension EquityBreakdown {
    mutating func update(from equity: Equity<LegalEntity>.Statistics, in context: GameContext) {
        let (country, culture): (
            country: [CountryID: (share: Int64, PieChartLabel)],
            culture: [String: (share: Int64, PieChartLabel)]
        ) = equity.owners.reduce(
            into: ([:], [:])
        ) {
            // Don’t have a way of representing non-pop owners yet.
            guard case .pop(let id) = $1.id,
            let pop: Pop = context.pops.table.state[id] else {
                return
            }
            if  let country: CountryID = context.planets[pop.home.planet]?.occupied,
                let country: Country = context.countries.state[country] {
                let label: PieChartLabel = .init(color: country.color, name: country.name)
                $0.country[country.id, default: (0, label)].share += $1.shares
            }
            if  let culture: Culture = context.cultures.state[pop.nat] {
                let label: PieChartLabel = .init(color: culture.color, name: culture.id)
                $0.culture[culture.id, default: (0, label)].share += $1.shares
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
extension EquityBreakdown: JavaScriptEncodable {
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
