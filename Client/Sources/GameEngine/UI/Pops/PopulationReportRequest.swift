import GameIDs
import JavaScriptKit
import JavaScriptInterop

@frozen public struct PopulationReportRequest {
    @usableFromInline let subject: PopID?
    @usableFromInline let details: PopDetailsTab?
    @usableFromInline let detailsTier: ResourceTierIdentifier?
    @usableFromInline let column: PopulationReport.ColumnControl?
    @usableFromInline let filter: PopulationReport.Filter?
}
extension PopulationReportRequest {
    @frozen public enum ObjectKey: JSString, Sendable {
        case subject
        case details
        case detailsTier
        case column
        case filter
    }
}
extension PopulationReportRequest: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            subject: try js[.subject]?.decode(),
            details: try js[.details]?.decode(),
            detailsTier: try js[.detailsTier]?.decode(),
            column: try js[.column]?.decode(),
            filter: try js[.filter]?.decode()
        )
    }
}
