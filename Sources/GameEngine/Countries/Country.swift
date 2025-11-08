import Color
import GameEconomy
import GameIDs
import GameRules
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
    var culturePreferred: String
    /// The accepted foreign cultures of the country, if any.
    ///
    /// For example, the United Nations is an “Earther” country that starts the game with
    /// “Lunan” as an accepted culture.
    var culturesAccepted: [String]

    /// The tiles this country controls.
    var controlledWorlds: [PlanetID]
    /// The tiles this country controls.
    var controlledTiles: [Address]

    var researched: [Technology]
    var minwage: Int64
}
extension Country {
    enum ObjectKey: JSString, Sendable {
        case id
        case currency
        case article
        case name
        case long
        case color
        case culture_preferred
        case cultures_accepted
        case controlled_worlds
        case controlled_tiles
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
        js[.culture_preferred] = self.culturePreferred
        js[.cultures_accepted] = self.culturesAccepted
        js[.controlled_worlds] = self.controlledWorlds
        js[.controlled_tiles] = self.controlledTiles
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
            culturePreferred: try js[.culture_preferred].decode(),
            culturesAccepted: try js[.cultures_accepted]?.decode() ?? [],
            controlledWorlds: try js[.controlled_worlds]?.decode() ?? [],
            controlledTiles: try js[.controlled_tiles]?.decode() ?? [],
            researched: try js[.researched]?.decode() ?? [],
            minwage: try js[.minwage].decode(),
        )
    }
}
