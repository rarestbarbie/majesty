import Color
import GameIDs
import GameRules
import GameState
import GameTerrain
import HexGrids
import Vector
import VectorCharts

struct PlanetContext: RuntimeContext {
    let type: _NoMetadata
    var state: Planet

    var motion: (global: CelestialMotion?, local: CelestialMotion?)
    var position: (global: Vector3, local: Vector3)

    var grid: PlanetGrid

    init(type: _NoMetadata, state: Planet) {
        self.type = type
        self.state = state

        self.motion = (nil, nil)
        self.position = (.zero, .zero)

        self.grid = .init()
    }
}
extension PlanetContext {
    subscript(tile: Int) -> PlanetGrid.Tile {
        _read   { yield  self.grid.tiles.values[tile] }
        _modify { yield &self.grid.tiles.values[tile] }
    }
}
extension PlanetContext {
    mutating func afterIndexCount(
        world: borrowing GameWorld,
        context: GameContext.TerritoryPass
    ) throws {
        if  let orbit: Planet.Orbit = self.state.orbit,
            let orbits: Planet = context.planets[orbit.orbits] {
            let motion: CelestialMotion = .init(
                orbit: orbit,
                of: self.state.id,
                around: orbits.mass
            )

            self.position.global = motion.position(world.date)
            self.motion.global = motion
        }

        if  let opposes: PlanetID = self.state.opposes,
            let opposes: Planet = context.planets[opposes],
            let orbit: Planet.Orbit = opposes.orbit {
            let orbit: CelestialMotion = .init(
                orbit: orbit,
                of: opposes.id,
                around: self.state.mass
            )
            let motion: CelestialMotion = orbit.pair(
                massOfSatellite: opposes.mass,
                massOfPrimary: self.state.mass
            )

            self.position.local = motion.position(world.date)
            self.motion.local = motion
        } else {
            self.motion.local = nil
        }
    }

    mutating func advance(turn: inout Turn, context: GameContext) throws {}
}
