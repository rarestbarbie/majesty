import D
import GameIDs
import GameRules
import GameUI

extension PlanetGrid {
    struct TileSnapshot: Identifiable, Sendable {
        let id: Address
        let name: String?
        let properties: RegionalProperties?
        let terrain: TerrainMetadata
        let geology: GeologicalMetadata
    }
}
extension PlanetGrid.TileSnapshot {
    var pops: PopulationStats { self.properties?.pops ?? .init() }
}
extension PlanetGrid.TileSnapshot {
    func tooltip(
        _ layer: MinimapLayer,
    ) -> Tooltip? {
        let pops: PopulationStats = self.pops
        return .instructions(style: .borderless) {
            switch layer {
            case .Terrain:
                $0[>] = "\(self.terrain.title) (\(self.geology.title))"

            case .Population:
                $0["Population"] = pops.free.total[/3]
                $0[>] {
                    $0["Free"] = pops.free.total[/3]
                    $0["Enslaved"] = ??pops.enslaved.total[/3]
                }

            case .AverageMilitancy:
                let (free, _): (Double, of: Double) = pops.free.mil
                $0["Average militancy"] = free[..2]
                let enslaved: (average: Double, of: Double) = pops.enslaved.mil
                if  enslaved.of > 0 {
                    $0[>] = """
                    The average militancy of the slave population is \(
                        enslaved.average[..2],
                        style: enslaved.average > 1.0 ? .neg : .em
                    )
                    """
                }
            case .AverageConsciousness:
                let (free, _): (Double, of: Double) = pops.free.con
                $0["Average consciousness"] = free[..2]
                let enslaved: (average: Double, of: Double) = pops.enslaved.con
                if  enslaved.of > 0 {
                    $0[>] = """
                    The average consciousness of the slave population is \(
                        enslaved.average[..2],
                        style: enslaved.average > 1.0 ? .neg : .em
                    )
                    """
                }
            }

            if let name: String = self.name {
                $0[>] = "\(name)"
            }
        }
    }
}
