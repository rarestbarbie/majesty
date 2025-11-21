import GameIDs
import GameRules
import JavaScriptInterop
import JavaScriptKit

@frozen public struct CountrySeed: Identifiable {
    public var id: CountryID?
    public let name: CountryName
    /// The ambient (or “default”) culture of the country, e.g. “Martian”.
    public let culturePreferred: Symbol
    /// The accepted foreign cultures of the country, if any.
    ///
    /// For example, the United Nations is an “Earther” country that starts the game with
    /// “Lunan” as an accepted culture.
    public let culturesAccepted: [Symbol]
    public let researched: [Symbol]
    public let currency: Currency
    public let minwage: Int64
    /// The tiles this country controls.
    public let tiles: [Address]
}
extension CountrySeed {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case name
        case culture_preferred
        case cultures_accepted
        case researched
        case currency
        case minwage
        case tiles
    }
}
extension CountrySeed: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.id = try js[.id]?.decode()
        self.name = try js[.name].decode()
        self.culturePreferred = try js[.culture_preferred].decode()
        self.culturesAccepted = try js[.cultures_accepted]?.decode() ?? []
        self.researched = try js[.researched]?.decode() ?? []
        self.currency = try js[.currency].decode()
        self.minwage = try js[.minwage].decode()
        self.tiles = try js[.tiles]?.decode() ?? []
    }
}
