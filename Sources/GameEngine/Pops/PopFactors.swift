import D
import GameIDs
import GameConditions

protocol PopFactors: PopProperties {
    associatedtype Matrix: ConditionMatrix<Decimal, Double>

    var region: RegionalProperties { get }
    var stats: Pop.Stats { get }
}
extension PopFactors {
    var demotion: Matrix {
        .init(base: 0%) {
            if case .aristocratic = self.occupation.mode {
                $0[true] {
                    $0 = -2‰
                } = { "\(+$0[%]): Pop is \(em: "aristocratic")" }
            } else {
                $0[1 - self.stats.employmentBeforeEgress] {
                    $0[$1 >= 0.1] = +2‱
                    $0[$1 >= 0.2] = +1‱
                    $0[$1 >= 0.3] = +1‱
                    $0[$1 >= 0.4] = +1‱
                } = { "\(+$0[%]): Unemployment is above \(em: $1[%0])" }
            }

            $0[self.y.fl] {
                $0[$1 < 1.00] = +1‰
                $0[$1 < 0.75] = +5‰
                $0[$1 < 0.50] = +2‰
                $0[$1 < 0.25] = +2‰
            } = { "\(+$0[%]): Getting less than \(em: $1[%0]) of Life Needs" }

        } factors: {
            $0[self.y.fx] {
                $0[$1 > 0.25] = -90%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Luxury Needs" }
            $0[self.y.fe] {
                $0[$1 > 0.75] = -50%
                $0[$1 > 0.5] = -25%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Everyday Needs" }

            $0[self.y.mil] {
                $0[$1 >= 1.0] = -10%
                $0[$1 >= 2.0] = -10%
                $0[$1 >= 3.0] = -10%
                $0[$1 >= 4.0] = -10%
                $0[$1 >= 5.0] = -10%
                $0[$1 >= 6.0] = -10%
                $0[$1 >= 7.0] = -10%
                $0[$1 >= 8.0] = -10%
                $0[$1 >= 9.0] = -10%
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            let culture: Culture = self.region.country.culturePreferred
            if case .Ward = self.type.stratum {
                $0[true] {
                    $0 = -100%
                } = { "\(+$0[%]): Pop is \(em: "enslaved")" }
            } else if self.race == culture.id {
                $0[true] {
                    $0 = -5%
                } = { "\(+$0[%]): Culture is \(em: culture.name)" }
            } else {
                $0[true] {
                    $0 = +100%
                } = { "\(+$0[%]): Culture is not \(em: culture.name)" }
            }
        }
    }

    var promotion: Matrix {
        .init(base: 0%) {
            $0[self.y.mil] {
                $0[$1 >= 3.0] = -2‱
                $0[$1 >= 5.0] = -2‱
                $0[$1 >= 7.0] = -3‱
                $0[$1 >= 9.0] = -3‱
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            switch self.type.stratum {
            case .Owner:
                $0[self.y.fx] {
                    $0[$1 >= 0.25] = +3‰
                    $0[$1 >= 0.50] = +3‰
                    $0[$1 >= 0.75] = +3‰
                } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Luxury Needs" }

            case _:
                break
            }

            $0[self.y.con] {
                $0[$1 >= 1.0] = +1‱
                $0[$1 >= 2.0] = +1‱
                $0[$1 >= 3.0] = +1‱
                $0[$1 >= 4.0] = +1‱
                $0[$1 >= 5.0] = +1‱
                $0[$1 >= 6.0] = +1‱
                $0[$1 >= 7.0] = +1‱
                $0[$1 >= 8.0] = +1‱
                $0[$1 >= 9.0] = +1‱
            } = { "\(+$0[%]): Consciousness is above \(em: $1[..1])" }

        } factors: {
            $0[self.y.fl] {
                $0[$1 < 1.00] = -100%
            } = { "\(+$0[%]): Getting less than \(em: $1[%0]) of Life Needs" }

            $0[self.y.fe] {
                $0[$1 >= 0.1] = -10%
                $0[$1 >= 0.2] = -10%
                $0[$1 >= 0.3] = -10%
                $0[$1 >= 0.4] = -10%
                $0[$1 >= 0.5] = -10%
                $0[$1 >= 0.6] = -10%
                $0[$1 >= 0.7] = -10%
                $0[$1 >= 0.8] = -10%
                $0[$1 >= 0.9] = -10%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Everyday Needs" }

            $0[self.y.mil] {
                $0[$1 >= 2.0] = -20%
                $0[$1 >= 4.0] = -10%
                $0[$1 >= 6.0] = -10%
                $0[$1 >= 8.0] = -10%
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            let culture: Culture = self.region.country.culturePreferred
            if case .Ward = self.type.stratum {
                $0[true] {
                    $0 = -100%
                } = { "\(+$0[%]): Pop is \(em: "enslaved")" }
            } else if self.race == culture.id {
                $0[true] {
                    $0 = +5%
                } = { "\(+$0[%]): Culture is \(em: culture.name)" }
            } else {
                $0[true] {
                    $0 = -75%
                } = { "\(+$0[%]): Culture is not \(em: culture.name)" }
            }
        }
    }
}
