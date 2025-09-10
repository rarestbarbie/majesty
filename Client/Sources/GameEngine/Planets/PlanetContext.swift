import Color
import GameRules
import GameState
import GameTerrain
import HexGrids
import OrderedCollections
import Vector
import VectorCharts

struct PlanetContext {
    var state: Planet

    var motion: (global: CelestialMotion?, local: CelestialMotion?)
    var position: (global: Vector3, local: Vector3)
    var occupied: CountryID?

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
    mutating func compute(in context: GameContext.TerritoryPass) throws {
        if  let orbit: Planet.Orbit = self.state.orbit,
            let orbits: Planet = context.planets[orbit.orbits] {
            let motion: CelestialMotion = .init(
                orbit: orbit,
                of: self.state.id,
                around: orbits.mass
            )

            self.position.global = motion.position(context.date)
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

    mutating func resurface(
        rotate: HexRotation?,
        size: Int8,
        terrainDefault: TerrainMetadata
    ) {
        if  self.size != size {
            self.reshape(size: size, terrainDefault: terrainDefault)
        }
        if  let rotate: HexRotation {
            /// OrderedDictionary is a value type, which does the Right Thing here, as we do
            /// not want to copy data from newly updated cells.
            for source: Cell in self.cells.values {
                let id: HexCoordinate
                switch rotate {
                case .ccw:
                    switch source.id {
                    case .x:                id = .x
                    case .n(let q, let r):  id = .n(r + q, -q)
                    case .e(let φ):         id = .e(φ == 5 ? 0 : φ + 1)
                    case .s(let q, let r):  id = .s(r + q, -q)
                    }

                case .cw:
                    switch source.id {
                    case .x:                id = .x
                    case .n(let q, let r):  id = .n(-r, r + q)
                    case .e(let φ):         id = .e(φ == 0 ? 5 : φ - 1)
                    case .s(let q, let r):  id = .s(-r, r + q)
                    }
                }

                self.cells[id]?.copy(from: source)
            }
        }
    }

    private mutating func reshape(
        size: Int8,
        terrainDefault: TerrainMetadata
    ) {
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

    func grid(_ color: (Cell) -> Color) -> [PlanetGridCell] {
        self.grid { (color($0), nil, nil, nil) }
    }
    func grid(_ color: (Cell) -> Double) -> [PlanetGridCell] {
        self.grid { (nil, color($0), nil, nil) }
    }
    func grid(_ color: (Cell) -> (x: Double, y: Double)) -> [PlanetGridCell] {
        self.grid {
            let (x, y): (Double, Double) = color($0)
            return (nil, x, y, nil)
        }
    }
    func grid(_ color: (Cell) -> (x: Double, y: Double, z: Double)) -> [PlanetGridCell] {
        self.grid {
            let (x, y, z): (Double, Double, Double) = color($0)
            return (nil, x, y, z)
        }
    }

    private func grid(
        _ color: (Cell) -> (color: Color?, x: Double?, y: Double?, z: Double?)
    ) -> [PlanetGridCell] {
        let radius: Double = 1.5 * Double.init(1 + self.size)
        let center: (north: Vector2, south: Vector2) = (
            north: .init(-radius, 0),
            south: .init(+radius, 0),
        )

        let tilt: HexRotation? = self.size > 2 ? .ccw : nil

        var cells: [PlanetGridCell] = [] ; cells.reserveCapacity(self.cells.count)
        for (id, cell): (HexCoordinate, Cell) in self.cells {
            let shape: (HexagonPath, HexagonPath?)

            switch id {
            case .x:
                shape.0 = .init(c: .zero, q: 0, r: 0, tilt: tilt)
                shape.1 = nil

            case .n(let q, let r):
                shape.0 = .init(c: center.north, q: q, r: r, tilt: tilt)
                shape.1 = nil

            case .e(let φ):
                let θ: Int8 = φ > 2 ? 8 - φ : 2 - φ
                shape.0 = .init(c: center.north, φ: φ, z: self.size, tilt: tilt)
                shape.1 = .init(c: center.south, φ: θ, z: self.size, tilt: tilt?.inverted)

            case .s(let q, let r):
                /// Project the southern hemisphere as if it were viewed from the south pole.
                let (q, r): (Int8, Int8) = (-q, r + q)
                shape.0 = .init(c: center.south, q: q, r: r, tilt: tilt?.inverted)
                shape.1 = nil
            }

            let (color, x, y, z): (Color?, Double?, Double?, Double?) = color(cell)
            let cell: PlanetGridCell = .init(
                id: id,
                shape: shape,
                color: color,
                x: x,
                y: y,
                z: z
            )

            cells.append(cell)
        }
        return cells
    }
}
