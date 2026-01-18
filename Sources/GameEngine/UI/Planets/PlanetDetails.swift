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

    private var gdp: PieChart<Resource, ColorReference>?
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
            $0[.gdp, (+), tooltip: .TileGDP] = tile.Δ.stats.economy.gdp[/3]
        }
        self.gdp = cache.ledger.breakdownGDP(
            rules: cache.rules,
            region: self.id
        )
        self.gdpGraph.update(
            with: tile.history.suffix(365),
            date: cache.date,
            digits: 4
        ) {
            Double.init($0.gdp)
        }
    }
}
extension PlanetDetails: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case open

        case name
        case terms

        case gdp
        case gdpGraph
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.open] = self.open
        js[.name] = self.tile?.name
        js[.terms] = self.terms
        js[.gdp] = self.gdp
        js[.gdpGraph] = self.gdpGraph
    }
}
