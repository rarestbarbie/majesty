import D
import GameIDs
import GameUI
import JavaScriptKit
import JavaScriptInterop
import VectorCharts
import VectorCharts_JavaScript

struct OwnershipBreakdown<Tab>: Sendable where Tab: OwnershipTab {
    private var country: PieChart<CountryID, PieChartLabel>?
    private var culture: PieChart<CultureID, PieChartLabel>?
    private var gender: PieChart<Gender, PieChartLabel>?
    private var terms: [Term]

    init() {
        self.country = nil
        self.culture = nil
        self.gender = nil
        self.terms = []
    }
}
extension OwnershipBreakdown {
    mutating func update(
        from asset: some LegalEntitySnapshot<Tab.State.ID>,
        in context: borrowing GameUI.Cache
    ) {
        let equity: Equity<LEI>.Snapshot = asset.equity
        let (country, culture, gender): (
            country: [CountryID: (share: Int64, PieChartLabel)],
            culture: [CultureID: (share: Int64, PieChartLabel)],
            gender: [Gender: (share: Int64, PieChartLabel)]
        ) = equity.owners.reduce(
            into: ([:], [:], [:])
        ) {
            if  let country: Country = context.countries[$1.country] {
                let label: PieChartLabel = .init(
                    color: country.name.color,
                    name: country.name.short
                )
                $0.country[country.id, default: (0, label)].share += $1.shares
            }
            if  let culture: CultureID = $1.culture,
                let culture: Culture = context.rules.pops.cultures[culture] {
                let label: PieChartLabel = .init(color: culture.color, name: culture.name)
                $0.culture[culture.id, default: (0, label)].share += $1.shares
            }
            if  let gender: Gender = $1.gender {
                let label: PieChartLabel = .init(
                    style: gender.code.name,
                    name: gender.singularTabular
                )
                $0.gender[gender, default: (0, label)].share += $1.shares
            }
        }

        self.country = .init(
            values: country.sorted { $0.key < $1.key }
        )
        self.culture = .init(
            values: culture.sorted { $0.key < $1.key }
        )
        self.gender = .init(
            values: gender.sorted { $0.key.sortingRadially < $1.key.sortingRadially }
        )

        self.terms = Term.list {
            let shares: TooltipInstruction.Ticker = equity.shareCount[/3] ^^ equity.issued

            $0[.shares, (-), tooltip: Tab.tooltipShares] = shares
            $0[.stockPrice, (+)] = asset.Δ.px[..3]
            $0[.stockAttraction, (+)] = asset.Δ.profitability[%1]
        }
    }
}
extension OwnershipBreakdown: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case country
        case culture
        case gender
        case terms
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Ownership
        js[.country] = self.country
        js[.culture] = self.culture
        js[.gender] = self.gender
        js[.terms] = self.terms
    }
}
