import Color
import GameEconomy
import GameIDs
import GameRules
import GameStarts
import JavaScriptInterop
import JavaScriptKit

struct Country: Identifiable {
    let id: CountryID
    var name: CountryName
    /// The ambient (or “default”) culture of the country, e.g. “Martian”.
    var culturePreferred: String
    /// The accepted foreign cultures of the country, if any.
    ///
    /// For example, the United Nations is an “Earther” country that starts the game with
    /// “Lunan” as an accepted culture.
    var culturesAccepted: [String]

    var researched: [Technology]
    var currency: Currency
    var minwage: Int64

    /// The tiles this country controls.
    var tilesControlled: [Address]
}
extension Country {
    enum ObjectKey: JSString, Sendable {
        case id
        case currency
        case name
        case culture_preferred
        case cultures_accepted
        case tiles_controlled
        case researched
        case minwage
    }
}
extension Country: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.currency] = self.currency
        js[.name] = self.name
        js[.culture_preferred] = self.culturePreferred
        js[.cultures_accepted] = self.culturesAccepted
        js[.tiles_controlled] = self.tilesControlled
        js[.researched] = self.researched
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
            minwage: try js[.minwage].decode(),
            tilesControlled: try js[.tiles_controlled]?.decode() ?? [],
        )
    }
}
