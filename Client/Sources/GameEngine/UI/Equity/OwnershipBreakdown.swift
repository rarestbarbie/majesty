import GameState
import JavaScriptKit
import JavaScriptInterop
import VectorCharts
import VectorCharts_JavaScript

struct OwnershipBreakdown<Tab> where Tab: OwnershipTab {
    private var country: PieChart<CountryID, PieChartLabel>?
    private var culture: PieChart<String, PieChartLabel>?
    private var state: Equity<LegalEntity>.Statistics?

    init() {
        self.country = nil
        self.culture = nil
        self.state = nil
    }
}
extension OwnershipBreakdown {
    mutating func update(from equity: Equity<LegalEntity>.Statistics, in context: GameContext) {
        let (country, culture): (
            country: [CountryID: (share: Int64, PieChartLabel)],
            culture: [String: (share: Int64, PieChartLabel)]
        ) = equity.owners.reduce(
            into: ([:], [:])
        ) {
            if  let country: Country = context.countries.state[$1.country] {
                let label: PieChartLabel = .init(color: country.color, name: country.name)
                $0.country[country.id, default: (0, label)].share += $1.shares
            }
            if  let culture: String = $1.culture,
                let culture: Culture = context.cultures.state[culture] {
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

        self.state = equity
    }
}
extension OwnershipBreakdown: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case country
        case culture

        case shares
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Ownership
        js[.country] = self.country
        js[.culture] = self.culture

        js[.shares] = self.state?.shares.outstanding
    }
}
