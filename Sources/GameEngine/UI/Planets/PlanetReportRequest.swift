import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct PlanetReportRequest {
    @usableFromInline let subject: PlanetID?
    @usableFromInline let details: PlanetDetailsTab?
}
extension PlanetReportRequest {
    @frozen public enum ObjectKey: JSString, Sendable {
        case subject
        case details
    }
}
extension PlanetReportRequest: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.subject] = self.subject
        js[.details] = self.details
    }
}
extension PlanetReportRequest: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            details: try js[.details]?.decode(),
        )
    }
}
