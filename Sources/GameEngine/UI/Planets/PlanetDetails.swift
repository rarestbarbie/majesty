import Color
import ColorReference
import D
import GameIDs
import GameMetrics
import GameUI
import JavaScriptInterop
import VectorCharts

struct PlanetDetails {
    let id: Address
    var open: PlanetMapLayer

    private var tile: TileSnapshot?
    private var terms: [Term]

    private var produced: PieChart<Resource, ColorReference>?
    private var consumed: PieChart<Resource, ColorReference>?
    private var gdp: PieChart<EconomicLedger.Industry, ColorReference>?
    private var gdpGraph: TimeSeries

    init(id: Address, focus: Focus) {
        self.id = id
        self.open = focus.layer
        self.tile = nil
        self.terms = []
        self.gdp = nil
        self.gdpGraph = .init()
    }
}
extension PlanetDetails: PersistentReportDetails {
    mutating func refocus(on focus: Focus) {
        self.open = focus.layer
    }
}
extension PlanetDetails {
    mutating func update(from tile: TileSnapshot, in cache: borrowing GameUI.Cache) {
        self.tile = tile
        self.terms = Term.list {
            $0[.gdp, +, tooltip: .TileGDP] = tile.Δ.stats.gdp[/3]
        }
        (
            produced: self.produced,
            consumed: self.consumed
        ) = cache.ledger.z.economy.breakdownProduction(
            rules: cache.rules,
            region: self.id
        )
        self.gdp = cache.ledger.z.economy.breakdownIndustries(
            rules: cache.rules,
            region: self.id
        )
        self.gdpGraph.update(
            with: tile.history.suffix(365),
            date: cache.date,
            labels: [
                .style("gdp"),
                .style("gnp"),
            ],
            digits: 4,
        ) {
            [Double.init($0.gdp), Double.init($0.gnp)]
        } adjust: {
            $0.min = 0
        }
    }
}
extension PlanetDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case open

        case name
        case terms

        case produced
        case consumed
        case gdp
        case gdpGraph
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.open] = self.open
        js[.name] = self.tile?.name
        js[.terms] = self.terms
        js[.produced] = self.produced
        js[.consumed] = self.consumed
        js[.gdp] = self.gdp
        js[.gdpGraph] = self.gdpGraph
    }
}
