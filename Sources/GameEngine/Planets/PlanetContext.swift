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
    var size: Int8

    init(type: _NoMetadata, state: Planet) {
        self.type = type
        self.state = state

        self.motion = (nil, nil)
        self.position = (.zero, .zero)
        self.size = 0
    }
}
extension PlanetContext {
    var snapshot: PlanetSnapshot {
        .init(
            state: self.state,
            motion: (self.motion.global, self.motion.local),
            position: (self.position.global, self.position.local),
            grid: .init(radius: self.size)
        )
    }
}
extension PlanetContext {
    mutating func startIndexCount() {
    }
    mutating func afterIndexCount(
        world: borrowing GameWorld,
        _context: GameContext.TerritoryPass
    ) throws {
        if  let orbit: Planet.Orbit = self.state.orbit,
            let orbits: Planet = _context.planets[orbit.orbits] {
            let motion: CelestialMotion = .init(
                orbit: orbit,
                of: self.state.id,
                around: orbits.mass
            )

            self.position.global = motion.position(world.date)
            self.motion.global = motion
        }

        if  let opposes: PlanetID = self.state.opposes,
            let opposes: Planet = _context.planets[opposes],
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
