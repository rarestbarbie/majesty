import GameState
import JavaScriptKit
import JavaScriptInterop

public struct CelestialView {
    private let subject: GameID<Planet>
    private var bodies: [CelestialBody]
    private var radius: Double

    init(subject: GameID<Planet>) {
        self.subject = subject
        self.bodies = []
        self.radius = 0
    }
}
extension CelestialView {
    static func open(subject: GameID<Planet>, in context: GameContext) throws -> Self {
        var view: Self = .init(subject: subject)
        try view.update(in: context)
        return view
    }

    mutating func update(in context: GameContext) throws {
        self.bodies.removeAll()

        var radius: Double
        let scale: Double
        if  let primary: PlanetContext = context.planets[self.subject] {
            //  Default view distance begins at 10 times the planet radius.
            radius = primary.state.radius * (10 / AU)
            scale = primary.state.radius

            let primary: CelestialBody = .init(
                id: primary.state.id,
                at: primary.position.local,
                name: primary.state.name,
                size: 1,
                color: primary.state.color,
                sprite: primary.state.sprite
            )

            self.bodies.append(primary)
        } else {
            throw CelestialViewError.noSuchWorld(self.subject)
        }

        for world: PlanetContext in context.planets {
            guard let orbit: CelestialOrbit = world.state.orbit,
            case self.subject = orbit.orbits else {
                continue
            }

            radius = max(radius, orbit.a)

            let size: Double = .sqrt(world.state.radius / scale)
            let body: CelestialBody = .init(
                id: world.state.id,
                at: world.position.global,
                name: world.state.name,
                size: size,
                color: world.state.color,
                sprite: world.state.sprite
            )
            self.bodies.append(body)
        }

        self.radius = radius
    }
}
extension CelestialView {
    @frozen public enum ObjectKey: JSString, Sendable {
        case subject
        case bodies
        case radius
    }
}
extension CelestialView: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.subject] = self.subject
        js[.bodies] = self.bodies
        js[.radius] = self.radius
    }
}
