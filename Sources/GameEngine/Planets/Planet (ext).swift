import GameIDs
import GameState
import GameTerrain

extension Planet {
    func motion(
        in context: RuntimeStateTable<PlanetContext>
    )  -> (global: CelestialMotion?, local: CelestialMotion?) {
        let global: CelestialMotion?
        let local: CelestialMotion?
        if  let orbit: Planet.Orbit = self.orbit,
            let orbits: Planet = context[orbit.orbits] {
            let motion: CelestialMotion = .init(
                orbit: orbit,
                of: self.id,
                around: orbits.mass
            )

            global = motion
        } else {
            global = nil
        }

        if  let opposes: PlanetID = self.opposes,
            let opposes: Planet = context[opposes],
            let orbit: Planet.Orbit = opposes.orbit {
            let orbit: CelestialMotion = .init(
                orbit: orbit,
                of: opposes.id,
                around: self.mass
            )
            let motion: CelestialMotion = orbit.pair(
                massOfSatellite: opposes.mass,
                massOfPrimary: self.mass
            )

            local = motion
        } else {
            local = nil
        }
        return (global, local)
    }
}
