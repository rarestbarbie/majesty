import ColorReference
import D
import GameIDs
import GameUI
import JavaScriptInterop
import VectorCharts
import VectorCharts_JavaScript

struct PortfolioBreakdown<Tab>: Sendable where Tab: PortfolioTab {
    private var country: PieChart<CountryID, ColorReference>?
    private var industry: PieChart<EconomicLedger.Industry, ColorReference>?
    private var terms: [Term]

    init() {
        self.country = nil
        self.industry = nil
        self.terms = []
    }
}
extension PortfolioBreakdown {
    mutating func update(
        from pop: PopSnapshot,
        in cache: borrowing GameUI.Cache
    ) {
        let context: GameUI.CacheContext = cache.context
        let (country, industry): (
            country: [CountryID: (share: Double, ColorReference)],
            industry: [EconomicLedger.Industry: (share: Double, ColorReference)],
        ) = pop.portfolio.reduce(
            into: ([:], [:])
        ) {
            let industry: EconomicLedger.Industry
            let country: CountryID
            switch $1.asset {
            case .reserve:
                fatalError("Reserves should not be included in portfolio breakdowns")
            case .building(let id):
                guard let building: BuildingSnapshot = cache.buildings[id] else {
                    fatalError("Missing building snapshot for portfolio breakdown")
                }
                industry = .building(building.type)
                country = building.region.occupiedBy

            case .factory(let id):
                guard let factory: FactorySnapshot = cache.factories[id] else {
                    fatalError("Missing factory snapshot for portfolio breakdown")
                }
                industry = .factory(factory.type)
                country = factory.region.occupiedBy

            case .pop(let id):
                guard let pop: PopSnapshot = cache.pops[id] else {
                    fatalError("Missing pop snapshot for portfolio breakdown")
                }
                industry = .slavery(pop.type.race)
                country = pop.region.occupiedBy
            }

            $0.country[country, default: (0, context.color(country))].share += $1.value
            $0.industry[industry, default: (0, context.rules.color(industry))].share += $1.value
        }

        self.country = .init(
            values: country.sorted { $0.key < $1.key }
        )
        self.industry = .init(
            values: industry.sorted { $0.key < $1.key }
        )

        self.terms = Term.list {
            $0[.portfolio, (+), tooltip: .PopPortfolioValue] = pop.Δ.μ.portfolioValue[/3..2]
        }
    }
}
extension PortfolioBreakdown: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case type
        case country
        case industry
        case terms
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = Tab.Portfolio
        js[.country] = self.country
        js[.industry] = self.industry
        js[.terms] = self.terms
    }
}
