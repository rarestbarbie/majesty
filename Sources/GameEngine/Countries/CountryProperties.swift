import GameRules
import GameIDs

final class CountryProperties {
    var intrinsic: Country
    private(set) var modifiers: CountryModifiers

    init(intrinsic state: Country) {
        self.intrinsic = state
        self.modifiers = .init()
    }
}
extension CountryProperties: Identifiable {
    var id: CountryID { self.intrinsic.id }
}
extension CountryProperties {
    var currency: Country.Currency { self.intrinsic.currency }
    var minwage: Int64 { self.intrinsic.minwage }
    var culturePreferred: String { self.intrinsic.culturePreferred }
}
extension CountryProperties {
    func update(rules: GameRules) {
        self.modifiers = .init()
        self.modifiers.update(from: self.intrinsic.researched, rules: rules)
    }
}
