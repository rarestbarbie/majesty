import D
import GameIDs
import GameUI
import JavaScriptKit
import JavaScriptInterop
import VectorCharts
import VectorCharts_JavaScript

struct OwnershipBreakdown<Tab> where Tab: OwnershipTab {
    private var country: PieChart<CountryID, PieChartLabel>?
    private var culture: PieChart<String, PieChartLabel>?
    private var equity: Equity<LEI>.Statistics?
    private var terms: [Term]

    init() {
        self.country = nil
        self.culture = nil
        self.equity = nil
        self.terms = []
    }
}
extension OwnershipBreakdown {
    mutating func update(
        from asset: some LegalEntityContext<Tab.State>,
        in context: GameContext
    ) {
        let equity: Equity<LEI>.Statistics = asset.equity
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

        self.terms = Term.list {
            let shares: TooltipInstruction.Ticker = equity.shareCount[/3]
                ^^ asset.state.equity.issued

            $0[.shares, (-), tooltip: Tab.tooltipShares] = shares
            $0[.stockPrice, (+)] = asset.state.Δ.px[..3]
            $0[.stockAttraction, (+)] = asset.state.Δ.pa[%1]
        }

        self.equity = equity
    }
}
extension OwnershipBreakdown: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case country
        case culture
        case terms
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Ownership
        js[.country] = self.country
        js[.culture] = self.culture
        js[.terms] = self.terms
    }
}
