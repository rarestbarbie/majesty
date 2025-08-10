import GameEngine
import GameRules
import HexGrids
import OrderedCollections
import Vector
import VectorCharts

struct PlanetContext {
    var state: Planet

    var motion: (global: CelestialMotion?, local: CelestialMotion?)
    var position: (global: Vector3, local: Vector3)
    var occupied: GameID<Country>?

    var cells: OrderedDictionary<HexCoordinate, Cell>
    var size: Int8

    init(type _: Metadata, state: Planet) {
        self.state = state

        self.motion = (nil, nil)
        self.position = (.zero, .zero)
        self.occupied = nil

        self.cells = [:]
        self.size = 0
    }
}
extension PlanetContext: RuntimeContext {
    mutating func compute(in context: GameState) throws {
        if  let orbit: CelestialOrbit = self.state.orbit,
            let orbits: Planet = context.planets[orbit.orbits] {
            let motion: CelestialMotion = .init(
                orbit: orbit,
                of: self.state.id,
                around: orbits.mass
            )

            self.position.global = motion.position(context.date)
            self.motion.global = motion
        }

        if  let opposes: GameID<Planet> = self.state.opposes,
            let opposes: Planet = context.planets[opposes],
            let orbit: CelestialOrbit = opposes.orbit {
            let orbit: CelestialMotion = .init(
                orbit: orbit,
                of: opposes.id,
                around: self.state.mass
            )
            let motion: CelestialMotion = orbit.pair(
                massOfSatellite: opposes.mass,
                massOfPrimary: self.state.mass
            )

            self.position.local = motion.position(context.date)
            self.motion.local = motion
        } else {
            self.motion.local = nil
        }
    }
    mutating func advance(in context: GameContext, on map: inout GameMap) throws {
    }
}
extension PlanetContext {
    var surface: PlanetSurface {
        .init(
            id: self.state.id,
            size: self.size,
            grid: self.cells.values.map {
                .init(id: $0.id, type: $0.type.name, tile: $0.tile)
            }
        )
    }

    mutating func replace(
        surface defined: PlanetSurface?,
        symbols: GameRules.Symbols,
        rules: GameRules,
        terrainDefault: TerrainMetadata,
    ) throws {
        let template: HexGrid
        let terrain: [HexCoordinate: (TerrainMetadata, PlanetTile)]
        if  let defined: PlanetSurface {
            template = .init(radius: defined.size)
            terrain = try defined.grid.reduce(into: [:]) {
                let terrain: TerrainType = try symbols[terrain: $1.type]
                if let terrain: TerrainMetadata = rules.terrains[terrain] {
                    $0[$1.id] = (terrain, $1.tile)
                }
            }
        } else {
            template = .init(radius: 0)
            terrain = [:]
        }

        self.size = template.radius
        self.cells = template.reduce(into: [:]) {
            let terrain: (type: TerrainMetadata, tile: PlanetTile)? = terrain[$1]
            $0[$1] = PlanetContext.Cell.init(
                id: $1,
                type: terrain?.type ?? terrainDefault,
                tile: terrain?.tile ?? .init()
            )
        }
    }

    mutating func reshape(
        size: Int8,
        terrainDefault: TerrainMetadata
    ) {
        if  self.size != size {
            let template: HexGrid = .init(radius: size)

            self.size = size
            self.cells = template.reduce(into: [:]) {
                $0[$1] = self.cells[$1] ?? PlanetContext.Cell.init(
                    id: $1,
                    type: terrainDefault,
                    tile: .init()
                )
            }
        }
    }

    var grid: [PlanetGridCell] {
        let radius: Double = 1.5 * Double.init(1 + self.size)
        let center: (north: Vector2, south: Vector2) = (
            north: .init(-radius, 0),
            south: .init(+radius, 0),
        )

        let tilt: HexRotation? = self.size > 2 ? .cw : nil

        var cells: [PlanetGridCell] = [] ; cells.reserveCapacity(self.cells.count)
        for (id, cell): (HexCoordinate, Cell) in self.cells {
            let shape: (HexagonPath, HexagonPath?)

            switch id {
            case .n(let q, let r):
                shape.0 = .init(c: center.north, q: q, r: r, tilt: tilt)
                shape.1 = nil

            case .e(let φ):
                let θ: Int8 = φ > 2 ? 8 - φ : 2 - φ
                shape.0 = .init(c: center.north, φ: φ, z: self.size, tilt: tilt)
                shape.1 = .init(c: center.south, φ: θ, z: self.size, tilt: tilt?.inverted)

            case .s(let q, let r):
                shape.0 = .init(c: center.south, q: q, r: r, tilt: tilt?.inverted)
                shape.1 = nil
            }

            let cell: PlanetGridCell = .init(
                id: id,
                shape: shape,
                color: cell.type.color
            )

            cells.append(cell)
        }
        return cells
    }
}
