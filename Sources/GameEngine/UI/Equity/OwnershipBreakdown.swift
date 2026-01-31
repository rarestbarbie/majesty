import ColorReference
import D
import GameIDs
import GameUI
import JavaScriptInterop
import VectorCharts
import VectorCharts_JavaScript

struct OwnershipBreakdown<Tab>: Sendable where Tab: OwnershipTab {
    private var country: PieChart<CountryID, ColorReference>?
    private var race: PieChart<CultureID, ColorReference>?
    private var gender: PieChart<Gender?, ColorReference>?
    private var terms: [Term]

    init() {
        self.country = nil
        self.race = nil
        self.gender = nil
        self.terms = []
    }
}
extension OwnershipBreakdown {
    mutating func update(
        from asset: some LegalEntitySnapshot<Tab.State.ID>,
        in context: GameUI.CacheContext
    ) {
        let equity: Equity<LEI>.Snapshot = asset.equity
        let (country, race, gender): (
            country: [CountryID: (share: Int64, ColorReference)],
            race: [CultureID: (share: Int64, ColorReference)],
            gender: [Gender?: (share: Int64, ColorReference)]
        ) = equity.owners.reduce(
            into: ([:], [:], [:])
        ) {
            if  let country: CountryID = context.tiles[$1.region]?.country?.occupiedBy {
                $0.country[country, default: (0, context.color(country))].share += $1.shares
            }
            if  let race: Culture = context.rules.pops.cultures[$1.culture] {
                let label: ColorReference = .color(race.color)
                $0.race[race.id, default: (0, label)].share += $1.shares
            }
            if  let gender: Gender = $1.gender {
                let label: ColorReference = .style(gender.code.name)
                $0.gender[gender, default: (0, label)].share += $1.shares
            } else {
                let label: ColorReference = .style("NONE")
                $0.gender[nil, default: (0, label)].share += $1.shares
            }
        }

        self.country = .init(
            values: country.sorted { $0.key < $1.key }
        )
        self.race = .init(
            values: race.sorted { $0.key < $1.key }
        )
        self.gender = .init(
            values: gender.sorted { $0.key?.sortingRadially <? $1.key?.sortingRadially }
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
        case race
        case gender
        case terms
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Ownership
        js[.country] = self.country
        js[.race] = self.race
        js[.gender] = self.gender
        js[.terms] = self.terms
    }
}
