import Color
import GameRules
import GameState
import GameTerrain
import HexGrids
import Vector
import VectorCharts

struct PlanetContext: RuntimeContext {
    var state: Planet

    var motion: (global: CelestialMotion?, local: CelestialMotion?)
    var position: (global: Vector3, local: Vector3)
    var occupied: CountryID?

    var grid: PlanetGrid

    init(type _: Metadata, state: Planet) {
        self.state = state

        self.motion = (nil, nil)
        self.position = (.zero, .zero)
        self.occupied = nil

        self.grid = .init()
    }
}
extension PlanetContext {
    mutating func compute(
        map: borrowing GameMap,
        context: GameContext.TerritoryPass
    ) throws {
        if  let orbit: Planet.Orbit = self.state.orbit,
            let orbits: Planet = context.planets[orbit.orbits] {
            let motion: CelestialMotion = .init(
                orbit: orbit,
                of: self.state.id,
                around: orbits.mass
            )

            self.position.global = motion.position(map.date)
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

            self.position.local = motion.position(map.date)
            self.motion.local = motion
        } else {
            self.motion.local = nil
        }
    }

    mutating func advance(map: inout GameMap, context: GameContext) throws {}
}
