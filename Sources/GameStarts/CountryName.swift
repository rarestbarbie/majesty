import Color
import JavaScriptInterop

@frozen public struct CountryName {
    /// The word “The”, if it precedes the name of the country.
    public let article: String?
    /// The short name of the country, e.g. “Mars”. Must be unique.
    public let short: String
    /// The long name of the country, e.g. “Commonwealth of Mars”, without any article.
    public let long: String
    /// The map color of the country. Does not need to be unique.
    public let color: Color
}
extension CountryName {
    @frozen public enum ObjectKey: JSString, Sendable {
        case article
        case short
        case long
        case color
    }
}
extension CountryName: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.article] = self.article
        js[.short] = self.short
        js[.long] = self.long
        js[.color] = self.color
    }
}
extension CountryName: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            article: try js[.article]?.decode(),
            short: try js[.short].decode(),
            long: try js[.long].decode(),
            color: try js[.color].decode()
        )
    }
}
