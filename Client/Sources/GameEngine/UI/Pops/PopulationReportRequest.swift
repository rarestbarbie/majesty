import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct PopulationReportRequest {
    @usableFromInline let subject: PopID?
    @usableFromInline let details: PopDetailsTab?
    @usableFromInline let column: PopulationReport.ColumnControl?
    @usableFromInline let filter: PopulationReport.Filter?
}
extension PopulationReportRequest {
    @frozen public enum ObjectKey: JSString, Sendable {
        case subject
        case details
        case column
        case filter
    }
}
extension PopulationReportRequest: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.subject] = self.subject
        js[.details] = self.details
        js[.column] = self.column
        js[.filter] = self.filter
    }
}
extension PopulationReportRequest: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            details: try js[.details]?.decode(),
            column: try js[.column]?.decode(),
            filter: try js[.filter]?.decode()
        )
    }
}
