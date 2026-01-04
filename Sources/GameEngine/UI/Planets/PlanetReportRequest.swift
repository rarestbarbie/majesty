import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct PlanetReportRequest {
    @usableFromInline let subject: Address?
    @usableFromInline let details: PlanetDetailsTab?
    @usableFromInline let filter: PlanetID?
}
extension PlanetReportRequest {
    @frozen public enum ObjectKey: JSString, Sendable {
        case subject
        case details
        case filter
    }
}
extension PlanetReportRequest: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            details: try js[.details]?.decode(),
            filter: try js[.filter]?.decode()
        )
    }
}
