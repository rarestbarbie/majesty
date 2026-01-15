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
