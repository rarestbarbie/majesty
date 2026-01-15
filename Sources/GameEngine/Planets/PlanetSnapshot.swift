import GameRules
import GameTerrain
import GameIDs
import HexGrids
import Vector

struct PlanetSnapshot: Sendable {
    let state: Planet
    let motion: (global: CelestialMotion?, local: CelestialMotion?)
    let position: (global: Vector3, local: Vector3)
}
extension PlanetSnapshot {
    var grid: HexGrid {
        .init(radius: self.state.size)
    }
}
