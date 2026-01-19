import Color
import GameEconomy
import GameIDs
import GameRules
import GameStarts
import JavaScriptInterop

struct Country: Identifiable {
    let id: CountryID
    var name: CountryName
    /// The ambient (or “default”) culture of the country, e.g. “Martian”.
    var culturePreferred: CultureID
    /// The accepted foreign cultures of the country, if any.
    ///
    /// For example, the United Nations is an “Earther” country that starts the game with
    /// “Lunan” as an accepted culture.
    var culturesAccepted: [CultureID]

    var researched: [Technology]
    var currency: CurrencyID
    var suzerain: CountryID?
    var minwage: Int64

    /// The tiles this country controls.
    var tilesControlled: [Address]
}
extension Country {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case culture_preferred
        case cultures_accepted
        case tiles_controlled
        case researched
        case currency
        case suzerain
        case minwage
    }
}
extension Country: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.culture_preferred] = self.culturePreferred
        js[.cultures_accepted] = self.culturesAccepted
        js[.tiles_controlled] = self.tilesControlled
        js[.researched] = self.researched
        js[.currency] = self.currency
        js[.suzerain] = self.suzerain
        js[.minwage] = self.minwage
    }
}
extension Country: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            name: try js[.name].decode(),
            culturePreferred: try js[.culture_preferred].decode(),
            culturesAccepted: try js[.cultures_accepted]?.decode() ?? [],
            researched: try js[.researched]?.decode() ?? [],
            currency: try js[.currency].decode(),
            suzerain: try js[.suzerain]?.decode(),
            minwage: try js[.minwage].decode(),
            tilesControlled: try js[.tiles_controlled]?.decode() ?? [],
        )
    }
}
