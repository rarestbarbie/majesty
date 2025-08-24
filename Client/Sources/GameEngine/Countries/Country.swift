import Color
import GameEconomy
import GameRules
import GameState
import JavaScriptInterop
import JavaScriptKit

struct Country: IdentityReplaceable {
    var id: CountryID
    var currency: Currency
    /// The word “The”, if it precedes the name of the country.
    var article: String?
    /// The short name of the country, e.g. “Mars”.
    var name: String
    /// The long name of the country, e.g. “Commonwealth of Mars”, without any article.
    var long: String
    /// The map color of the country. Does not need to be unique.
    var color: Color
    /// The ambient (or “default”) culture of the country, e.g. “Martian”.
    var white: String
    /// The accepted foreign cultures of the country, if any.
    ///
    /// For example, the United Nations is an “Earther” country that starts the game with
    /// “Lunan” as an accepted culture.
    var accepted: [String]
    /// The celestial bodies that this country controls.
    var territory: [PlanetID]
    var researched: [Technology]
    var minwage: Int64
}
extension Country {
    var policies: CountryPolicies {
        .init(currency: self.currency.id, minwage: self.minwage, culture: self.white)
    }
}
extension Country {
    enum ObjectKey: JSString, Sendable {
        case id
        case currency
        case article
        case name
        case long
        case color
        case white
        case accepted
        case territory
        case researched
        case minwage
    }
}
extension Country: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.currency] = self.currency
        js[.article] = self.article
        js[.name] = self.name
        js[.long] = self.long
        js[.color] = self.color
        js[.white] = self.white
        js[.accepted] = self.accepted
        js[.territory] = self.territory
        js[.researched] = self.researched
        js[.minwage] = self.minwage
    }
}
extension Country: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            currency: try js[.currency].decode(),
            article: try js[.article]?.decode(),
            name: try js[.name].decode(),
            long: try js[.long].decode(),
            color: try js[.color].decode(),
            white: try js[.white].decode(),
            accepted: try js[.accepted]?.decode() ?? [],
            territory: try js[.territory].decode(),
            researched: try js[.researched]?.decode() ?? [],
            minwage: try js[.minwage].decode(),
        )
    }
}
