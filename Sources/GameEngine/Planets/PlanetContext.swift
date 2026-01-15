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

    init(type: _NoMetadata, state: Planet) {
        self.type = type
        self.state = state

        self.motion = (nil, nil)
        self.position = (.zero, .zero)
    }
}
extension PlanetContext {
    var snapshot: PlanetSnapshot {
        .init(
            state: self.state,
            motion: (self.motion.global, self.motion.local),
            position: (self.position.global, self.position.local),
        )
    }
}
extension PlanetContext {
    static func move(
        _ planets: RuntimeStateTable<PlanetContext>
    ) -> [(global: CelestialMotion?, local: CelestialMotion?)] {
        planets.map {
            let global: CelestialMotion?
            let local: CelestialMotion?
            if  let orbit: Planet.Orbit = $0.orbit,
                let orbits: Planet = planets[orbit.orbits] {
                let motion: CelestialMotion = .init(
                    orbit: orbit,
                    of: $0.id,
                    around: orbits.mass
                )

                global = motion
            } else {
                global = nil
            }

            if  let opposes: PlanetID = $0.opposes,
                let opposes: Planet = planets[opposes],
                let orbit: Planet.Orbit = opposes.orbit {
                let orbit: CelestialMotion = .init(
                    orbit: orbit,
                    of: opposes.id,
                    around: $0.mass
                )
                let motion: CelestialMotion = orbit.pair(
                    massOfSatellite: opposes.mass,
                    massOfPrimary: $0.mass
                )

                local = motion
            } else {
                local = nil
            }
            return (global, local)
        }
    }
}
extension PlanetContext {
    mutating func startIndexCount() {
    }
    mutating func afterIndexCount(
        world: borrowing GameWorld,
    ) {
        if  let motion: CelestialMotion = self.motion.global {
            self.position.global = motion.position(world.date)
        }
        if  let motion: CelestialMotion = self.motion.local {
            self.position.local = motion.position(world.date)
        }
    }

    mutating func advance(turn: inout Turn, context: GameContext) throws {}
}
