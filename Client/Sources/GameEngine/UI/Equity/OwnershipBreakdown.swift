import GameState
import JavaScriptKit
import JavaScriptInterop
import VectorCharts
import VectorCharts_JavaScript

struct OwnershipBreakdown<Tab> where Tab: OwnershipTab {
    private var country: PieChart<CountryID, PieChartLabel>?
    private var culture: PieChart<String, PieChartLabel>?
    private var equity: Equity<LEI>.Statistics?
    private var state: Tab.State?

    init() {
        self.country = nil
        self.culture = nil
        self.equity = nil
        self.state = nil
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

        self.equity = equity
        self.state = asset.state
    }
}
extension OwnershipBreakdown: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case country
        case culture

        case shares
        case yesterday_px = "y_px"
        case yesterday_pa = "y_pa"
        case today_px = "t_px"
        case today_pa = "t_pa"

    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Ownership
        js[.country] = self.country
        js[.culture] = self.culture

        js[.shares] = self.equity?.shares.outstanding
        js[.yesterday_px] = self.state?.yesterday.px
        js[.yesterday_pa] = self.state?.yesterday.pa
        js[.today_px] = self.state?.today.px
        js[.today_pa] = self.state?.today.pa
    }
}
