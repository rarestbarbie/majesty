import Color
import GameRules
import GameTerrain
import HexGrids
import OrderedCollections
import Vector

struct PlanetGrid {
    var tiles: OrderedDictionary<HexCoordinate, Tile>
    var size: Int8

    init(
        tiles: OrderedDictionary<HexCoordinate, Tile> = [:],
        size: Int8 = 0
    ) {
        self.tiles = tiles
        self.size = size
    }
}
extension PlanetGrid {
    mutating func assign(
        governedBy: CountryProperties,
        occupiedBy: CountryProperties,
    ) {
        for tile: Int in self.tiles.values.indices {
            self.tiles.values[tile].update(
                governedBy: governedBy,
                occupiedBy: occupiedBy
            )
        }
    }
}
extension PlanetGrid {
    mutating func replace(
        surface: PlanetSurface?,
        symbols: GameSaveSymbols,
        rules: GameRules,
        terrainDefault: TerrainMetadata,
        geologyDefault: GeologicalMetadata
    ) throws {
        self.tiles = try Self.resolve(
            surface: surface,
            symbols: symbols,
            rules: rules,
        )
        self.reshape(
            size: surface?.size ?? 0,
            terrainDefault: terrainDefault,
            geologyDefault: geologyDefault
        )
    }

    mutating func resurface(
        rotate: HexRotation?,
        size: Int8,
        terrainDefault: TerrainMetadata,
        geologyDefault: GeologicalMetadata
    ) {
        if  self.size != size {
            self.reshape(
                size: size,
                terrainDefault: terrainDefault,
                geologyDefault: geologyDefault
            )
        }
        if  let rotate: HexRotation {
            /// OrderedDictionary is a value type, which does the Right Thing here, as we do
            /// not want to copy data from newly updated tiles.
            for source: Tile in self.tiles.values {
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

                self.tiles[id]?.copy(from: source)
            }
        }
    }
}
extension PlanetGrid {
    private mutating func reshape(
        size: Int8,
        terrainDefault: TerrainMetadata,
        geologyDefault: GeologicalMetadata
    ) {
        let template: HexGrid = .init(radius: size)

        self.size = size
        self.tiles = template.reduce(into: [:]) {
            $0[$1] = self.tiles[$1] ?? Tile.init(
                id: $1,
                name: nil,
                terrain: terrainDefault,
                geology: geologyDefault
            )
        }
    }

    private static func resolve(
        surface: PlanetSurface?,
        symbols: GameSaveSymbols,
        rules: GameRules
    ) throws -> OrderedDictionary<HexCoordinate, Tile> {
        var tiles: OrderedDictionary<HexCoordinate, Tile> = [:]

        guard let surface: PlanetSurface else {
            return tiles
        }

        tiles.reserveCapacity(surface.grid.count)

        for tile: PlanetSurface.Tile in surface.grid {
            guard
            let terrain: TerrainMetadata = rules.terrains[
                try symbols[terrain: tile.terrain]
            ] else {
                fatalError("Missing terrain metadata for \(tile.terrain)!!!")
            }
            guard
            let geology: GeologicalMetadata = rules.geology[
                try symbols[geology: tile.geology]
            ] else {
                fatalError("Missing geological metadata for \(tile.geology)!!!")
            }

            tiles[tile.id] = Tile.init(
                id: tile.id,
                name: tile.name,
                terrain: terrain,
                geology: geology
            )
        }

        return tiles
    }
}
extension PlanetGrid {
    func color(_ color: (Tile) -> Color) -> [PlanetMapTile] {
        self.color { (color($0), nil, nil, nil) }
    }
    func color(_ color: (Tile) -> Double) -> [PlanetMapTile] {
        self.color { (nil, color($0), nil, nil) }
    }
    func color(_ color: (Tile) -> (x: Double, y: Double)) -> [PlanetMapTile] {
        self.color {
            let (x, y): (Double, Double) = color($0)
            return (nil, x, y, nil)
        }
    }
    func color(_ color: (Tile) -> (x: Double, y: Double, z: Double)) -> [PlanetMapTile] {
        self.color {
            let (x, y, z): (Double, Double, Double) = color($0)
            return (nil, x, y, z)
        }
    }

    private func color(
        _ color: (Tile) -> (color: Color?, x: Double?, y: Double?, z: Double?)
    ) -> [PlanetMapTile] {
        let radius: Double = 1.5 * Double.init(1 + self.size)
        let center: (north: Vector2, south: Vector2) = (
            north: .init(-radius, 0),
            south: .init(+radius, 0),
        )

        let tilt: HexRotation? = self.size > 2 ? .ccw : nil

        var tiles: [PlanetMapTile] = [] ; tiles.reserveCapacity(self.tiles.count)
        for (id, tile): (HexCoordinate, Tile) in self.tiles {
            let shape: (HexagonPath, HexagonPath?)

            switch id {
            case .x:
                shape.0 = .init(c: .zero, q: 0, r: 0, tilt: tilt)
                shape.1 = nil

            case .n(let q, let r):
                shape.0 = .init(c: center.north, q: q, r: r, tilt: tilt)
                shape.1 = nil

            case .e(let φ):
                let θ: Int8 = φ > 4 ? 10 - φ : 4 - φ
                shape.0 = .init(c: center.north, φ: φ, z: self.size, tilt: tilt)
                shape.1 = .init(c: center.south, φ: θ, z: self.size, tilt: tilt?.inverted)

            case .s(let q, let r):
                /// Project the southern hemisphere as if it were viewed from the south pole.
                let (q, r): (Int8, Int8) = (-q, r + q)
                shape.0 = .init(c: center.south, q: q, r: r, tilt: tilt?.inverted)
                shape.1 = nil
            }

            let (color, x, y, z): (Color?, Double?, Double?, Double?) = color(tile)
            let tile: PlanetMapTile = .init(
                id: id,
                shape: shape,
                color: color,
                x: x,
                y: y,
                z: z
            )

            tiles.append(tile)
        }
        return tiles
    }
}
