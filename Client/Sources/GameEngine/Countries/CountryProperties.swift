import GameEconomy
import GameRules
import GameState

final class CountryProperties {
    var intrinsic: Country
    private(set) var factories: FactoryModifiers

    init(intrinsic state: Country) {
        self.intrinsic = state
        self.factories = .init()
    }
}
extension CountryProperties: Identifiable {
    var id: CountryID { self.intrinsic.id }
}
extension CountryProperties {
    var currency: Fiat { self.intrinsic.currency.id }
    var minwage: Int64 { self.intrinsic.minwage }
    var culture: String { self.intrinsic.white }
}
extension CountryProperties {
    func technology(
        yield: (inout FactoryModifiers) -> ()
    ) {
        self.factories = .init()
        yield(&self.factories)
    }
}
