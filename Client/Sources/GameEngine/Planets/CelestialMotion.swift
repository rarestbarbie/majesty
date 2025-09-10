import GameState
import GameTerrain
import JavaScriptInterop
import JavaScriptKit
import RealModule
import Vector

@frozen public struct CelestialMotion {
    public var a: Double // AU
    public var e: Double
    public var i: Double
    public var ω: Double
    public var Ω: Double
    public var t: Double
    public var n: Double

    private init(a: Double, e: Double, i: Double, ω: Double, Ω: Double, t: Double, n: Double) {
        self.a = a
        self.e = e
        self.i = i
        self.ω = ω
        self.Ω = Ω
        self.t = t
        self.n = n
    }
}
extension CelestialMotion {
    private init(a: Double, e: Double, i: Double, ω: Double, Ω: Double, mass: Double) {
        let mu: Double = mass * G // m³ s⁻²
        let m: Double = a * AU // m

        let s: Double = (m * m * m / mu).squareRoot() // s / radian
        let n: Double = 86_400 / s // radians per day

        self.init(a: a, e: e, i: i, ω: ω, Ω: Ω, t: 0, n: n)
    }

    init(orbit: Planet.Orbit, of world: PlanetID, around mass: Double) {
        self.init(
            a: orbit.a,
            e: orbit.e,
            i: orbit.i,
            ω: orbit.ω,
            Ω: orbit.Ω,
            mass: mass
        )
    }

    consuming func pair(massOfSatellite: Double, massOfPrimary: Double) -> Self {
        self.a *= massOfSatellite / (massOfPrimary + massOfSatellite)
        self.ω += .pi
        return self
    }
}
extension CelestialMotion {
    public func position(_ d: GameDate) -> Vector3 {
        self.position(Double.init(d.rawValue) * self.n)
    }

    public func position(_ t: Double) -> Vector3 {
        let t: Double = t + self.t
        // Sun should be at one of the foci
        let x: (Double, Double)
        let y: (Double, Double)

        x.0 = .cos(t) * self.a + self.a * self.e
        y.0 = .sin(t) * self.a * (1 - self.e * self.e).squareRoot()

        let ω: (sin: Double, cos: Double) = (.sin(self.ω), .cos(self.ω))

        x.1 = x.0 * ω.cos - y.0 * ω.sin
        y.1 = x.0 * ω.sin + y.0 * ω.cos

        let z: Double = x.1 * .sin(self.i)
        let w: Double = x.1 * .cos(self.i)

        let Ω: (sin: Double, cos: Double) = (.sin(self.Ω), .cos(self.Ω))
        return .init(
            w * Ω.cos - y.1 * Ω.sin,
            w * Ω.sin + y.1 * Ω.cos,
            z
        )
    }
}
extension CelestialMotion {
    func rendered() -> JSTypedArray<Float> {
        // This is probably faster than repeatedly calling a foreign subscript
        var array: [Float] = [] ; array.reserveCapacity(361 * 3)
        for i: Int in 0 ... 360 {
            let phi: Double = Double.init(i) * (.pi / 180.0)
            let p: Vector3 = self.position(phi)

            array.append(Float.init(p.x))
            array.append(Float.init(p.y))
            array.append(Float.init(p.z))
        }
        return JSTypedArray<Float>.init(array)
    }
}
