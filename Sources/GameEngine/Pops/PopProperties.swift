import GameIDs

protocol PopProperties: Differentiable<Pop.Dimensions> {
    var type: PopType { get }
}
extension PopProperties {
    var occupation: PopOccupation { self.type.occupation }
    var gender: Gender { self.type.gender }
    var race: CultureID { self.type.race }
}
extension PopProperties {
    var decadence: Double {
        0.1 * self.y.con
    }

    var needsScalePerCapita: (l: Double, e: Double, x: Double) {
        let decadence: Double = self.decadence
        return self.type.stratum <= .Ward ? (
            l: 1,
            e: 1,
            x: 1 + decadence
        ) : (
            l: 1 + decadence,
            e: 1 + decadence * 2,
            x: 1 + decadence * 3
        )
    }
}
